//
//  file_struct.h
//  iTorrent
//
//  Created by  XITRIX on 15.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

#ifndef file_struct_h
#define file_struct_h

typedef struct Files {
    int error;
    int size;
    char* title;
    char** file_name;
    long long* file_size;
    int* file_priority;
} Files;
#endif /* file_struct_h */
