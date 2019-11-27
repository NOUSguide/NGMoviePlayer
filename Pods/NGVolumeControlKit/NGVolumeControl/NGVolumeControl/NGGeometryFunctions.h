//
//  NGGeometryFunctions.h
//  NGVolumeControl
//
//  Created by Tretter Matthias on 05.03.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

NS_INLINE CGFloat NGDistanceBetweenCGPoints(CGPoint p1, CGPoint p2) {
    CGFloat dx = p1.x - p2.x;
    CGFloat dy = p1.y - p2.y;
    
    return (CGFloat)sqrt((double)(dx*dx+dy*dy));
}
