//
//  NYCommon.h
//  Pods
//
//  Created by niyao on 3/24/25.
//

#ifndef NYCommon_h
#define NYCommon_h
#ifdef DEBUG
    #define NYLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
    #define NYLog(fmt, ...) do {} while (0)
#endif


#endif /* NYCommon_h */
