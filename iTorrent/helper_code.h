//
//  helper_code.h
//  iTorrent
//
//  Created by Daniil Vinogradov on 17.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

#ifndef helper_code_h
#define helper_code_h

#include <stdio.h>
#include <fstream>

using namespace std;


bool exists (const std::string& name) {
	return ( access( name.c_str(), F_OK ) != -1 );
}

#endif /* helper_code_h */
