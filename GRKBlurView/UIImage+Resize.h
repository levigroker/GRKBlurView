//
//  UIImage+Resize.h
//
//  Created by Levi Brown on May 28, 2014.
//  Copyright (c) 2014 Levi Brown <mailto:levigroker@gmail.com>
//  This work is licensed under the Creative Commons Attribution 3.0
//  Unported License. To view a copy of this license, visit
//  http://creativecommons.org/licenses/by/3.0/ or send a letter to Creative
//  Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041,
//  USA.
//
//  The above attribution and the included license must accompany any version
//  of the source code. Visible attribution in any binary distributable
//  including this work (or derivatives) is not required, but would be
//  appreciated.
//

#import <UIKit/UIKit.h>

@interface UIImage (Resize)

/**
 *  Resizes the reciever to the given size in points at the current device resolution.
 *
 *  @param size The size to scale the receiver to.
 *
 *  @return A new UIImage instance scaled to the given size.
 *  @see http://stackoverflow.com/a/2658801/397210
 */
- (UIImage *)imageScaledToSize:(CGSize)size;

@end
