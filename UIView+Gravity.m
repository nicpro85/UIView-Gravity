//
//  Created by Nicolas Manzini on 23.01.14.
//  Free under MIT licence
//  Copyright (c) 2014 Nicolas Manzini.
//  Thanks to Daij-Djan for his help
//

#import "UIView+Gravity.h"
#import <objc/runtime.h>
#import <CoreMotion/CoreMotion.h>

@interface GravityManager : CMMotionManager

@property (strong, nonatomic) NSMutableArray * animatedViews;
@property (assign, nonatomic) CGFloat angle;

+ (instancetype)sharedManager;

- (void)addView:(UIView *)view;
- (void)removeView:(UIView *)view;

@end

static char MyCustomPropertyKey  = 0;

@implementation UIView (Gravity)

@dynamic followGravity;

+ (void)load
{
    SEL originalSelector  = NSSelectorFromString(@"dealloc");
    SEL overrideSelector  = @selector(xchg_dealloc);
    Method originalMethod = class_getInstanceMethod(self, originalSelector);
    Method overrideMethod = class_getInstanceMethod(self, overrideSelector);

    if (class_addMethod(self, originalSelector, method_getImplementation(overrideMethod), method_getTypeEncoding(overrideMethod)))
    {
        class_replaceMethod(self, overrideSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    }
    else
    {
        method_exchangeImplementations(originalMethod, overrideMethod);
    }
}

- (void)xchg_dealloc
{
    if (self.followGravity)
    {
        [[GravityManager sharedManager] removeView:self];
    }
    objc_setAssociatedObject(self, &MyCustomPropertyKey,  nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setFollowGravity:(BOOL)followGravity
{
    objc_setAssociatedObject(self, &MyCustomPropertyKey,  @(followGravity), OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    if (followGravity)
    {
        [[GravityManager sharedManager] addView:self];
    }
    else
    {
        [[GravityManager sharedManager] removeView:self];
    }
}

- (BOOL)followGravity
{
    NSNumber * followGravity = objc_getAssociatedObject(self, &MyCustomPropertyKey);
    // for nil case
    return followGravity ? followGravity.boolValue : NO;
}

@end

@implementation GravityManager

+ (instancetype)sharedManager
{
    static dispatch_once_t pred;
	static GravityManager * sharedManager = nil;
	dispatch_once(&pred, ^
    {
        sharedManager               = [[self alloc] init];
        sharedManager.animatedViews = @[].mutableCopy;
        sharedManager.deviceMotionUpdateInterval = 0.4;

        __weak typeof(sharedManager) weakManager = sharedManager;

        [sharedManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue]
                                           withHandler:^(CMDeviceMotion *motion, NSError *error)
         {
             CGFloat angle = 0.f;
             if((fabs(motion.gravity.x) < fabs(motion.gravity.y)))
             {
                 angle = (motion.gravity.y > 0) ? -M_PI : 0.f;
             }
             else
             {
                 angle = (motion.gravity.x > 0) ? -M_PI_2 : M_PI_2;
             }

             if (angle != sharedManager.angle)
             {
                 sharedManager.angle = angle;
                 CGAffineTransform transform = (angle == 0) ? CGAffineTransformIdentity : CGAffineTransformMakeRotation(angle);

                 [UIView animateWithDuration:.25
                                  animations:^
                  {
                      [weakManager.animatedViews setValue:[NSValue valueWithCGAffineTransform:transform]
                                                   forKey:@"transform"];
                  }];
             }
         }];
    });
	return sharedManager;
}

- (void)addView:(UIView *)view
{
    if([self.animatedViews indexOfObjectIdenticalTo:view] == NSNotFound)
    {
    	view.transform = 
    	(self.angle == 0) ? CGAffineTransformIdentity : CGAffineTransformMakeRotation(angle);
        [self.animatedViews addObject:view];
    }
}

- (void)removeView:(UIView *)view
{
    [self.animatedViews removeObject:view];
}

@end
