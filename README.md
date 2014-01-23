UIView+Gravity
==============

`UIView+Gravity.h` is a category on UIView that add a `@property (nonatomic) BOOL followGravity` on all `UIView` to let them rotate by 90 degree increment with the device rotation.

The `UIView` will remove itself from the animation whenever it gets deallocated. 
To make the view rotate, you simply set:

    UIView * view = [[UIView alloc] initWithFrame:frame];
    view.followGravity = YES;
    
The option is available on any other UIView subclass.

It's free and should work as is...

it imports

    #import <objc/runtime.h>
    #import <CoreMotion/CoreMotion.h>
    
which may requires to add `frameworks` to your project.

Thanks to Daij-Djan for the dealloc part.

