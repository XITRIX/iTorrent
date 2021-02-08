//
//  DiffAwareExtensions.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 01.08.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

#if TRANSMISSION
import ITorrentTransmissionFramework
#else
import ITorrentFramework
#endif

import DeepDiff

extension TorrentModel: DiffAware {}
extension TrackerModel: DiffAware {}
extension TorrentState: DiffAware {}
extension PeerModel: DiffAware {}
