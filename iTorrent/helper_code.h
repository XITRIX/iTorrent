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

#include <boost/archive/binary_oarchive.hpp>
#include <boost/archive/binary_iarchive.hpp>
#include <boost/serialization/map.hpp>
#include <boost/serialization/string.hpp>
#include <boost/serialization/list.hpp>

using namespace std;

template <typename ClassTo>
int Save(const std::string fname, const ClassTo &c)
{
	ofstream f(fname.c_str(), ios::binary);
	if (f.fail()) return -1;
	boost::archive::binary_oarchive oa(f);
	oa << c;
	return 0;
}

bool exists (const std::string& name) {
	return ( access( name.c_str(), F_OK ) != -1 );
}

#endif /* helper_code_h */
