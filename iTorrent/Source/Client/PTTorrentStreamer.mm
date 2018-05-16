

#import "PTTorrentStreamer.h"
#import <Foundation/Foundation.h>
#import <string>
#import <libtorrent/alert.hpp>
#import <libtorrent/alert_types.hpp>
#import <libtorrent/bencode.hpp>
#import "CocoaSecurity.h"
#import "PTTorrentStreamer+Protected.h"
#import <GCDWebServer/GCDWebServer.h>
#import <GCDWebServer/GCDWebServerFileRequest.h>
#import <GCDWebServer/GCDWebServerFileResponse.h>
#import <GCDWebServer/GCDWebServerPrivate.h>
#import <UIKit/UIApplication.h>
#import "NSString+Localization.h"
#import "PTSize.h"

#define ALERTS_LOOP_WAIT_MILLIS 500
#define PIECE_DEADLINE_MILLIS 100
#define LIBTORRENT_PRIORITY_SKIP 0
#define LIBTORRENT_PRIORITY_MAXIMUM 7

int MIN_PIECES = 0; //they are calculated by divind the 5% of a torrent file size with the size of a torrent piece

NSNotificationName const PTTorrentStatusDidChangeNotification = @"com.popcorntimetv.popcorntorrent.status.change";


using namespace libtorrent;

@implementation PTTorrentStreamer

+ (instancetype)sharedStreamer {
    static dispatch_once_t onceToken;
    static PTTorrentStreamer *sharedStreamer;
    dispatch_once(&onceToken, ^{
        sharedStreamer = [[PTTorrentStreamer alloc] init];
    });
    return sharedStreamer;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupSession];
    }
    return self;
}

- (NSString *)fileName {
    return _fileName;
}

- (NSString *)savePath {
    return _savePath;
}

- (PTTorrentStatus)torrentStatus {
    return _torrentStatus;
}

- (PTSize *)fileSize {
    return [PTSize sizeWithLongLong:_requiredSpace];
}

- (PTSize *)totalDownloaded {
    return [PTSize sizeWithLongLong:_totalDownloaded];
}


+ (NSString *)downloadDirectory {
    NSString *downloadDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"Downloads"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:downloadDirectory]) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:downloadDirectory
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if (error) return nil;
    }
    
    return downloadDirectory;
}

- (void)setupSession {
    error_code ec;
    
    firstPiece = -1;
    endPiece = 0;
    
    _session = new session();
    _session->set_alert_mask(alert::all_categories);
    _session->listen_on(std::make_pair(6881, 6889), ec);
    
    NSAssert(ec == nil, @"FATAL ERROR: Failed to open listen socket: %s", ec.message().c_str());
    
    session_settings settings = _session->settings();
    settings.announce_to_all_tiers = true;
    settings.announce_to_all_trackers = true;
    //settings.prefer_udp_trackers = false;
    settings.max_peerlist_size = 10000;
    _session->set_settings(settings);
    
    _requestedRangeInfo = [[NSMutableDictionary alloc] init];
    
    _status = torrent_status();
    if(self.mediaServer == nil)self.mediaServer = [[GCDWebServer alloc] init];
    
}

- (void)startStreamingFromFileOrMagnetLink:(NSString *)filePathOrMagnetLink
                                  progress:(PTTorrentStreamerProgress)progress
                               readyToPlay:(PTTorrentStreamerReadyToPlay)readyToPlay
                                   failure:(PTTorrentStreamerFailure)failure {
    [self startStreamingFromFileOrMagnetLink:filePathOrMagnetLink
                               directoryName:nil
                                    progress:progress
                                 readyToPlay:readyToPlay
                                     failure:failure];
    
}

- (void)startStreamingFromFileOrMagnetLink:(NSString *)filePathOrMagnetLink
                             directoryName:(NSString * _Nullable)directoryName
                                  progress:(PTTorrentStreamerProgress)progress
                               readyToPlay:(PTTorrentStreamerReadyToPlay)readyToPlay
                                   failure:(PTTorrentStreamerFailure)failure {
    self.progressBlock = progress;
    self.readyToPlayBlock = readyToPlay;
    self.failureBlock = failure;
    
    self.alertsQueue = dispatch_queue_create("com.popcorntimetv.popcorntorrent.alerts", DISPATCH_QUEUE_SERIAL);
    self.alertsLoopActive = YES;
    dispatch_async(self.alertsQueue, ^{
        [self alertsLoop];
    });
    
    error_code ec;
    add_torrent_params tp;
    
    NSString *MD5String = nil;
    
    if ([filePathOrMagnetLink hasPrefix:@"magnet"]) {
        NSString *magnetLink = filePathOrMagnetLink;
        tp.url = std::string([magnetLink UTF8String]);
        
        MD5String = [CocoaSecurity md5:magnetLink].hexLower;
    } else {
        NSString *filePath = filePathOrMagnetLink;
        NSError *error;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            NSData *fileData = [NSData dataWithContentsOfFile:filePath];
            MD5String = [CocoaSecurity md5WithData:fileData].hexLower;
            shared_ptr<torrent_info> ti1 = boost::make_shared<torrent_info>([filePathOrMagnetLink UTF8String], ec);
            tp.ti = ti1;
            if (ec) {
                error = [[NSError alloc] initWithDomain:@"com.popcorntimetv.popcorntorrent.error" code:-1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithCString:ec.message().c_str() encoding:NSUTF8StringEncoding]}];
            }
            MIN_PIECES = ((tp.ti->file_at([self indexOfLargestFileInTorrentWithTorrentInfo:tp.ti]).size*0.03)/tp.ti->piece_length());
        } else {
            error = [[NSError alloc] initWithDomain:@"com.popcorntimetv.popcorntorrent.error" code:-2 userInfo:@{NSLocalizedDescriptionKey: [NSString localizedStringWithFormat:@"File doesn't exist at path: %@".localizedString, filePath]}];
        }
        
        if (error) {
            if (failure) failure(error);
            return [self cancelStreamingAndDeleteData:NO];
        }
    }
    
    NSString *pathComponent = directoryName != nil ? directoryName : [MD5String substringToIndex:16];
    
    NSString *basePath = [[self class] downloadDirectory];
    
    if (!basePath) {
        NSError *error = [NSError errorWithDomain:@"com.popcorntimetv.popcorntorrent.error" code:-412 userInfo:@{NSLocalizedDescriptionKey: @"Could not create download directory".localizedString}];
        if (failure) failure(error);
        return [self cancelStreamingAndDeleteData:NO];
    }
    
    _savePath = [basePath stringByAppendingPathComponent:pathComponent];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:_savePath]) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:self.savePath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if (error) {
            if (failure) failure(error);
            return [self cancelStreamingAndDeleteData:NO];
        }
    }else{
        NSData *resumeData = [NSData dataWithContentsOfFile:[_savePath stringByAppendingString:@"/resumeData.fastresume"] ];
        if (resumeData != nil){
            unsigned long int len = resumeData.length;
            std::vector<char> resumeVector((char *)resumeData.bytes, (char *)resumeData.bytes + len);
            tp.resume_data = resumeVector;
        }
    }
    
    tp.save_path = std::string([self.savePath UTF8String]);
    tp.storage_mode = storage_mode_allocate;
    
    torrent_handle th = _session->add_torrent(tp, ec);
    
    if (ec) {
        NSError *error = [[NSError alloc] initWithDomain:@"com.popcorntimetv.popcorntorrent.error" code:-1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithCString:ec.message().c_str() encoding:NSUTF8StringEncoding]}];
        if (failure) failure(error);
        return [self cancelStreamingAndDeleteData:NO];
    }
    
    th.set_sequential_download(true);
    
    if (![filePathOrMagnetLink hasPrefix:@"magnet"]) {
        [self metadataReceivedAlert:th];
    }
    
    if(_session->is_paused())_session->resume();
    
#if TARGET_OS_IOS
  dispatch_async(dispatch_get_main_queue(), ^{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  });
#endif
}


#pragma mark - Fast Forward


- (BOOL)fastForwardTorrentForRange:(NSRange)range
{
    std::vector<torrent_handle> ths = _session->get_torrents();
    
    for(std::vector<torrent_handle>::size_type i = 0; i != ths.size(); i++) {
        boost::shared_ptr<const torrent_info> ti = ths[i].torrent_file();
        
        //get all the pieces in the movie
        int totalTorrentPieces = ti->num_pieces();
        
        //find the torrent piece corresponding to the requested piece of the movie
        peer_request request = ti->map_file([self indexOfLargestFileInTorrent:ths[i]], range.location, (int)range.length);
        
        //set first and last pieces
        int startPiece = request.piece;
        int finalPiece = startPiece + MIN_PIECES - 1;
        
        NSLog(@"new startPiece: %d", startPiece);
        
        //check if we are over the total pieces of the torrent
        if (finalPiece > totalTorrentPieces) {
            finalPiece = totalTorrentPieces - 1;
        }
        
        //set global variables
        firstPiece = startPiece;
        endPiece = finalPiece;
        
        //if we already have the requested part of the movie return immediately
        for(int j=startPiece; j<=finalPiece;j++){
            if (!ths[i].have_piece(j)) {
                break;
            }else if(j==finalPiece){
                return YES;
            }
        }
        
        //take control of the array from all of the other threads that might be accessing it
        mtx.lock();
        required_pieces.clear(); //clear all the pieces we wanted to download previously
        mtx.unlock();
        
        //start to download the requested part of the movie
        [self prioritizeNextPieces:ths[i]];
    }
    
    return NO;
    
}


- (void)cancelStreamingAndDeleteData:(BOOL)deleteData {
    
    std::vector<torrent_handle> ths = _session->get_torrents();
    for(std::vector<torrent_handle>::size_type i = 0; i != ths.size(); i++) {
        ths[i].pause();
        if (!deleteData && ths[i].need_save_resume_data())ths[i].save_resume_data();
        ths[i].flush_cache();
        _session->pause();
        if (deleteData)_session->remove_torrent(ths[i]);
    }
    
    required_pieces.clear();
    required_pieces.shrink_to_fit();
    
    [self.requestedRangeInfo removeAllObjects];
    _status = torrent_status();
    
    self.progressBlock = nil;
    self.readyToPlayBlock = nil;
    self.failureBlock = nil;
    if (self.mediaServer.isRunning)[self.mediaServer stop];
    [self.mediaServer removeAllHandlers];
    
    
    
    _savePath = nil;
    _fileName = nil;
    _requiredSpace = 0;
    _totalDownloaded = 0;
    firstPiece = -1;
    endPiece = 0;
    
    self.streaming = NO;
    _torrentStatus = (PTTorrentStatus){0, 0, 0, 0, 0, 0};
    _isFinished = false;
    
#if TARGET_OS_IOS
  dispatch_async(dispatch_get_main_queue(), ^{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  });
#endif
    
    if (deleteData) {
        self.alertsQueue = nil;
        self.alertsLoopActive = NO;
        [[NSFileManager defaultManager] removeItemAtPath:self.savePath error:nil];
        _session->abort();
        _session = nil;
        [self setupSession];
    }
}


#pragma mark - Alerts Loop


- (void)alertsLoop {
    std::deque<alert *> deque;
    time_duration max_wait = milliseconds(ALERTS_LOOP_WAIT_MILLIS);
    
    while ([self isAlertsLoopActive]) {
        const alert *ptr = _session->wait_for_alert(max_wait);
        if (ptr != nullptr && _session != nullptr) {
            _session->pop_alerts(&deque);
            for (std::deque<alert *>::iterator it = deque.begin(); it != deque.end(); ++it) {
                std::unique_ptr<alert> alert(*it);
                switch (alert->type()) {
                    case metadata_received_alert::alert_type:
                        [self metadataReceivedAlert:((metadata_received_alert *)alert.get())->handle];
                        break;
                        
                    case piece_finished_alert::alert_type:
                        [self pieceFinishedAlert:((piece_finished_alert *)alert.get())->handle forPieceIndex:((piece_finished_alert *)alert.get())->piece_index];
                        break;
                        // In case the video file is already fully downloaded
                    case torrent_finished_alert::alert_type:
                        [self torrentFinishedAlert:((torrent_finished_alert *)alert.get())->handle];
                        break;
                    case save_resume_data_alert::alert_type: {
                        torrent_status st = (((save_resume_data_alert *)alert.get())->handle).status(torrent_handle::query_save_path
                                                                                                     | torrent_handle::query_name);
                        [self resumeDataReadyAlertWithData:*((save_resume_data_alert *)alert.get())->resume_data andSaveDirectory:[NSString stringWithUTF8String:(st.save_path + "/resumeData.fastresume").c_str()]];
                        break;
                    }
                    default:
                        break;
                }
                alert = nil;
            }
            deque.clear();
        }
    }
}

- (void)prioritizeNextPieces:(torrent_handle)th {
    int next_required_piece = 0;
    
    if (firstPiece != -1) {
        next_required_piece = (int)firstPiece;
    } else {
        next_required_piece = required_pieces[MIN_PIECES - 1] + 1;
    }
    
    firstPiece = -1;
    
    mtx.lock();
    
    required_pieces.clear();
    
    std::vector<int> piece_priorities = th.piece_priorities();
    boost::shared_ptr<const torrent_info> ti = th.torrent_file();
    th.clear_piece_deadlines();//clear all deadlines on all pieces before we set new ones
    std::fill(piece_priorities.begin(), piece_priorities.end(), 1);
    //th.prioritize_pieces(piece_priorities);// clear all piece priorities before setting new ones
    
    for (int i = next_required_piece; i < next_required_piece + MIN_PIECES; i++) {
        if (i < ti->num_pieces()) {
            piece_priorities[i] = LIBTORRENT_PRIORITY_MAXIMUM;
            th.set_piece_deadline(i, PIECE_DEADLINE_MILLIS, torrent_handle::alert_when_available);
            required_pieces.push_back(i);
        }
    }
    th.prioritize_pieces(piece_priorities);
    mtx.unlock();
}

- (void)processTorrent:(torrent_handle)th {
    if ([self isStreaming]) return;
    
    self.streaming = YES;
    _status = th.status();
    
    boost::shared_ptr<const torrent_info> ti = th.torrent_file();
    int file_index = [self indexOfLargestFileInTorrent:th];
    file_entry fe = ti->file_at(file_index);
    std::string path = fe.path;
    _fileName = [NSString stringWithCString:path.c_str() encoding:NSUTF8StringEncoding];
    
    if (self.readyToPlayBlock) {
        [self startWebServerAndPlay];
    }
}

- (void)startWebServerAndPlay {
    __block NSURL *fileURL = [NSURL fileURLWithPath:[self.savePath stringByAppendingPathComponent:_fileName]];
    __weak __typeof__(self) weakSelf = self;
    
    [self.mediaServer addDefaultHandlerForMethod:@"GET" requestClass:[GCDWebServerRequest class] asyncProcessBlock:^(GCDWebServerRequest *request, GCDWebServerCompletionBlock completionBlock) {
        GCDWebServerFileResponse *response = [[GCDWebServerFileResponse alloc] init];
        
        if (request.hasByteRange) {
            response = [[GCDWebServerFileResponse alloc]initWithFile:fileURL.relativePath byteRange:request.byteRange];
        } else {
            response = [[GCDWebServerFileResponse alloc]initWithFile:fileURL.relativePath];
        }
        if (response == nil){
            GCDWebServerErrorResponse *newResponse = [GCDWebServerErrorResponse responseWithStatusCode:416];
            [response setValue:[NSString stringWithFormat:@"*/%lu",(unsigned long)request.byteRange.location] forAdditionalHeader:@"Content-Range"];
            completionBlock(newResponse);
            return;
        }
        [response setValue:@"*" forAdditionalHeader:@"Access-Control-Allow-Origin"];
        [response setValue:@"Content-Type" forAdditionalHeader:@"Access-Control-Expose-Headers"];
        
        if (!weakSelf.isFinished) {
            //if we have the parts downloaded already ready to go we deliver them below
            if ([weakSelf fastForwardTorrentForRange:request.byteRange]) {
                completionBlock(response);
            } else {
                //we now store the response and the completionBlock inside the requestedRangeInfo dictionary in order to retrieve it when we have downloaded the required pieces successfully and send the response at that time
                [weakSelf.requestedRangeInfo setObject:response forKey:@"response"];
                [weakSelf.requestedRangeInfo setObject:completionBlock forKey:@"completionBlock"];
            }
        } else {
            completionBlock(response);
        }
    }];
    
    [self.mediaServer startWithPort:50321 bonjourName:nil];
    
    __block NSURL *serverURL = self.mediaServer.serverURL;
    
    if (serverURL == nil) // `nil` when device is on cellular network.
    {
        serverURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://0.0.0.0:%i/", (int)self.mediaServer.port]];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakSelf.readyToPlayBlock) weakSelf.readyToPlayBlock(serverURL, fileURL);
    });
}


- (int)indexOfLargestFileInTorrent:(torrent_handle)th {
    boost::shared_ptr<const torrent_info> ti = th.torrent_file();
    return [self indexOfLargestFileInTorrentWithTorrentInfo:ti];
}

- (int)indexOfLargestFileInTorrentWithTorrentInfo:(boost::shared_ptr<const torrent_info>)ti {
    int files_count = ti->num_files();
    if (files_count > 1) {
        int64_t largest_size = -1;
        int largest_file_index = -1;
        for (int i = 0; i < files_count; i++) {
            file_entry fe = ti->file_at(i);
            if (fe.size > largest_size) {
                largest_size = fe.size;
                largest_file_index = i;
            }
        }
        return largest_file_index;
    }
    return 0;
}

#pragma mark - Alerts

- (void)metadataReceivedAlert:(torrent_handle)th {
    
    _requiredSpace = th.status().total_wanted;
    NSURL* savePathURL = [NSURL fileURLWithPath:self.savePath];
    NSDictionary *results = [savePathURL resourceValuesForKeys:@[NSURLVolumeAvailableCapacityKey] error:nil];
    NSNumber *availableSpace = results[NSURLVolumeAvailableCapacityKey];//get available space on device
    
    if (_requiredSpace > availableSpace.longLongValue) {
        NSString *description = [NSString localizedStringWithFormat:@"There is not enough space to download the torrent. Please clear at least %@ and try again.".localizedString, self.fileSize.stringValue];
        NSError *error = [[NSError alloc] initWithDomain:@"com.popcorntimetv.popcorntorrent.error" code:-4 userInfo:@{NSLocalizedDescriptionKey: description}];
        if (_failureBlock) _failureBlock(error);
        [self cancelStreamingAndDeleteData:NO];
        return;
    }
    
    int file_index = [self indexOfLargestFileInTorrent:th];
    
    std::vector<int> file_priorities = th.file_priorities();
    std::fill(file_priorities.begin(), file_priorities.end(), LIBTORRENT_PRIORITY_SKIP);
    file_priorities[file_index] = LIBTORRENT_PRIORITY_MAXIMUM;
    th.prioritize_files(file_priorities);
    
    boost::shared_ptr<const torrent_info> ti = th.torrent_file();
    MIN_PIECES = ((ti->file_at([self indexOfLargestFileInTorrent:th]).size*0.03)/ti->piece_length());
    int first_piece = ti->map_file(file_index, 0, 0).piece;
    for (int i = first_piece; i < first_piece + MIN_PIECES; i++) {
        required_pieces.push_back(i);
    }
    
    int64_t file_size = ti->file_at(file_index).size;
    int last_piece = ti->map_file(file_index, file_size - 1, 0).piece;
    for (int i = 0; i < 10; i++) {
        required_pieces.push_back(last_piece - i);
    }
    
    th.clear_piece_deadlines();
    std::vector<int> piece_priorities = th.piece_priorities();
    std::fill(piece_priorities.begin(), piece_priorities.end(), 1);
    th.prioritize_pieces(piece_priorities);
    for(std::vector<int>::size_type i = 0; i != required_pieces.size(); i++) {
        int piece = required_pieces[i];
        th.piece_priority(piece, LIBTORRENT_PRIORITY_MAXIMUM);
        th.set_piece_deadline(piece, PIECE_DEADLINE_MILLIS, torrent_handle::alert_when_available);
    }
    piece_priorities = th.piece_priorities();
    _status = th.status();
}

- (void)pieceFinishedAlert:(torrent_handle)th forPieceIndex:(int)index{
    _status = th.status();
    
    int requiredPiecesDownloaded = 0;
    BOOL allRequiredPiecesDownloaded = YES;
    
    auto copyRequired(required_pieces);
    
    for(std::vector<int>::size_type i = 0; i != copyRequired.size(); i++) {
        int piece = copyRequired[i];
        if(_session->is_paused())break;
        if (th.have_piece(piece) == false) {
            allRequiredPiecesDownloaded = NO;
        }else{
            requiredPiecesDownloaded++;
        }
    }
    
    int requiredPieces = (int)copyRequired.size();
    float bufferingProgress = 1.0 - (requiredPieces - requiredPiecesDownloaded)/(float)requiredPieces;
    _torrentStatus = {
        bufferingProgress,
        _status.progress,
        _status.download_rate,
        _status.upload_rate,
        _status.num_seeds,
        _status.num_peers
    };
    
    _totalDownloaded = _status.total_wanted_done;
    _isFinished = _status.is_finished;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_progressBlock) _progressBlock(_torrentStatus);
        [[NSNotificationCenter defaultCenter] postNotificationName:PTTorrentStatusDidChangeNotification object:self];
    });
    
    
    
    if (allRequiredPiecesDownloaded) {
        if (th.have_piece((int)endPiece) && self.requestedRangeInfo.count > 0) {
            GCDWebServerFileResponse *response = [self.requestedRangeInfo objectForKey:@"response"];
            GCDWebServerCompletionBlock completionBlock = [self.requestedRangeInfo objectForKey:@"completionBlock"];
            [self.requestedRangeInfo removeAllObjects];
            completionBlock(response);
        }
        if (MIN_PIECES == 0)[self metadataReceivedAlert:th];
        [self prioritizeNextPieces:th];
        [self processTorrent:th];
    }
}

- (void)torrentFinishedAlert:(torrent_handle)th {
    [self processTorrent:th];
    
    _torrentStatus = {
        1, 1,
        _status.download_rate,
        _status.upload_rate,
        _status.num_seeds,
        _status.num_peers
    };
    
    _totalDownloaded = _status.total_wanted_done;
    _isFinished = _status.is_finished;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_progressBlock) _progressBlock(_torrentStatus);
        [[NSNotificationCenter defaultCenter] postNotificationName:PTTorrentStatusDidChangeNotification object:self];
    });
    
#if TARGET_OS_IOS
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    });
#endif
    
    // Remove the torrent when its finished
    th.pause(false);
    _session->remove_torrent(th);
}

- (void) resumeDataReadyAlertWithData:(entry)resumeData andSaveDirectory:(NSString*)directory{
    self.alertsQueue = nil;
    self.alertsLoopActive = NO;
    std::vector<torrent_handle> ths = _session->get_torrents();
    for(std::vector<torrent_handle>::size_type i = 0; i != ths.size(); i++) {
        _session->remove_torrent(ths[i]);
    }
    std::stringstream ss;
    ss.unsetf(std::ios_base::skipws);
    bencode(std::ostream_iterator<char>(ss), resumeData);
    
    NSData *resumeDataFile = [[NSData alloc] initWithBytesNoCopy:(void*)ss.str().c_str() length:ss.str().size() freeWhenDone:false];
    NSAssert(resumeDataFile != nil, @"Resume data failed to be generated");
    [resumeDataFile writeToFile:[NSURL URLWithString:directory].relativePath atomically:NO];
    _session->abort();
    _session = nil;
    [self setupSession];
}

@end

