//
// 	UIImage+PRAutoAdjust.m
//
// 	Created by Pierre Rothmaler on 13.12.13.
//	This is free and unencumbered software released into the public domain.
//
//	Anyone is free to copy, modify, publish, use, compile, sell, or
//	distribute this software, either in source code form or as a compiled
//	binary, for any purpose, commercial or non-commercial, and by any
//	means.
//
//	In jurisdictions that recognize copyright laws, the author or authors
//	of this software dedicate any and all copyright interest in the
//	software to the public domain. We make this dedication for the benefit
//	of the public at large and to the detriment of our heirs and
//	successors. We intend this dedication to be an overt act of
//	relinquishment in perpetuity of all present and future rights to this
//	software under copyright law.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//	IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
//	OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
//	ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//	OTHER DEALINGS IN THE SOFTWARE.
//
//	For more information, please refer to <http://unlicense.org/>
//

#import "UIImage+PRAutoAdjust.h"

@implementation UIImage (PRAutoAdjust)

-(UIImage*)autoAdjustImage {
	CIImage * ciImage = [CIImage imageWithCGImage:[self imageWithOrientationUp].CGImage];

	NSArray * autoFilters = [ciImage autoAdjustmentFilters];
	for (CIFilter *ciFilter in autoFilters) {
		[ciFilter setValue:ciImage forKey:kCIInputImageKey];
		ciImage = [ciFilter valueForKey:kCIOutputImageKey];
	}

	CIContext * context = [CIContext contextWithOptions:nil];
	CGImageRef cgImage = [context createCGImage:ciImage fromRect:ciImage.extent];
	UIImage * uiImage = [UIImage imageWithCGImage:cgImage];
	CGImageRelease(cgImage);

	return uiImage;
}

// From: http://stackoverflow.com/a/5427890/1257059
- (UIImage *)imageWithOrientationUp {
	// No-op if the orientation is already correct
	if (self.imageOrientation == UIImageOrientationUp) return self;

	// We need to calculate the proper transformation to make the image upright.
	// We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
	CGAffineTransform transform = CGAffineTransformIdentity;

	switch (self.imageOrientation) {
		case UIImageOrientationDown:
		case UIImageOrientationDownMirrored:
			transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height);
			transform = CGAffineTransformRotate(transform, M_PI);
			break;

		case UIImageOrientationLeft:
		case UIImageOrientationLeftMirrored:
			transform = CGAffineTransformTranslate(transform, self.size.width, 0);
			transform = CGAffineTransformRotate(transform, M_PI_2);
			break;

		case UIImageOrientationRight:
		case UIImageOrientationRightMirrored:
			transform = CGAffineTransformTranslate(transform, 0, self.size.height);
			transform = CGAffineTransformRotate(transform, -M_PI_2);
			break;
		case UIImageOrientationUp:
		case UIImageOrientationUpMirrored:
			break;
	}

	switch (self.imageOrientation) {
		case UIImageOrientationUpMirrored:
		case UIImageOrientationDownMirrored:
			transform = CGAffineTransformTranslate(transform, self.size.width, 0);
			transform = CGAffineTransformScale(transform, -1, 1);
			break;

		case UIImageOrientationLeftMirrored:
		case UIImageOrientationRightMirrored:
			transform = CGAffineTransformTranslate(transform, self.size.height, 0);
			transform = CGAffineTransformScale(transform, -1, 1);
			break;
		case UIImageOrientationUp:
		case UIImageOrientationDown:
		case UIImageOrientationLeft:
		case UIImageOrientationRight:
			break;
	}

	// Now we draw the underlying CGImage into a new context, applying the transform
	// calculated above.
	CGContextRef ctx = CGBitmapContextCreate(NULL, self.size.width, self.size.height,
											 CGImageGetBitsPerComponent(self.CGImage), 0,
											 CGImageGetColorSpace(self.CGImage),
											 CGImageGetBitmapInfo(self.CGImage));
	CGContextConcatCTM(ctx, transform);
	switch (self.imageOrientation) {
		case UIImageOrientationLeft:
		case UIImageOrientationLeftMirrored:
		case UIImageOrientationRight:
		case UIImageOrientationRightMirrored:
			// Grr...
			CGContextDrawImage(ctx, CGRectMake(0,0,self.size.height,self.size.width), self.CGImage);
			break;

		default:
			CGContextDrawImage(ctx, CGRectMake(0,0,self.size.width,self.size.height), self.CGImage);
			break;
	}

	// And now we just create a new UIImage from the drawing context
	CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
	UIImage *img = [UIImage imageWithCGImage:cgimg];
	CGContextRelease(ctx);
	CGImageRelease(cgimg);

	return img;
}

@end
