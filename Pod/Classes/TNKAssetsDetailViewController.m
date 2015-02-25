//
//  TNKAssetsDetailViewController.m
//  Pods
//
//  Created by David Beck on 2/24/15.
//
//

#import "TNKAssetsDetailViewController.h"

@import Photos;
@import ObjectiveC;

#import "TNKAssetViewController.h"


@interface TNKAssetsDetailViewController () <UIGestureRecognizerDelegate, UIPageViewControllerDelegate, UIPageViewControllerDataSource>
{
    PHFetchResult *_fetchResult;
    
    BOOL _fullscreen;
}

@end

@implementation TNKAssetsDetailViewController

#pragma mark - Properties

- (void)setAssetCollection:(PHAssetCollection *)assetCollection {
    _assetCollection = assetCollection;
    
    if (_assetCollection != nil) {
        _fetchResult = [PHAsset fetchAssetsInAssetCollection:_assetCollection options:nil];
    } else {
        _fetchResult = [PHAssetCollection fetchMomentsWithOptions:nil];
    }
}


#pragma mark - Initialization

- (void)_init
{
    self.delegate = self;
    self.dataSource = self;
    self.hidesBottomBarWhenPushed = YES;
    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _init];
    }
    return self;
}

- (id)initWithTransitionStyle:(UIPageViewControllerTransitionStyle)style navigationOrientation:(UIPageViewControllerNavigationOrientation)navigationOrientation options:(NSDictionary *)originalOptions
{
    NSDictionary *options = @{
                              UIPageViewControllerOptionInterPageSpacingKey: @5.0,
                              };
    
    self = [super initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:options];
    if (self) {
        [self _init];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self _init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleBars:)];
    recognizer.delegate = self;
    [self.view addGestureRecognizer:recognizer];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

- (BOOL)prefersStatusBarHidden {
    return _fullscreen;
}

- (void)_updateTitle {
//    TNKAssetViewController *next = self.viewControllers.firstObject;
    
//    self.title = [NSString localizedStringWithFormat:NSLocalizedString(@"%1$d of %2$d", @"Fullscreen photo editing title showing the index of the current photo in the album. %1$d is the index of the current photo. %2$d is the total number of photos."), index + 1, _assets.count];
}


#pragma mark - Actions

- (IBAction)toggleBars:(id)sender {
    _fullscreen = !_fullscreen;
    [self.navigationController setNavigationBarHidden:_fullscreen animated:YES];
    
    [UIView animateWithDuration:0.2 animations:^{
        for (TNKAssetViewController *viewController in self.viewControllers) {
            viewController.selectButton.alpha = _fullscreen ? 0.0 : 1.0;
        }
        
        if (_fullscreen) {
            self.view.backgroundColor = [UIColor blackColor];
        } else {
            self.view.backgroundColor = [UIColor whiteColor];
        }
    }];
}

- (IBAction)toggleSelection:(UIButton *)sender {
    sender.selected = !sender.selected;
    
    NSIndexPath *indexPath = objc_getAssociatedObject(sender, @selector(indexPath));
    
    if (sender.selected) {
        [self.assetDelegate assetsDetailViewController:self selectAssetAtIndexPath:indexPath];
    } else {
        [self.assetDelegate assetsDetailViewController:self deselectAssetAtIndexPath:indexPath];
    }
}

- (TNKAssetViewController *)_assetViewControllerWithAssetAtIndexPath:(NSIndexPath *)indexPath {
    PHAsset *asset = nil;
    if (self.assetCollection != nil) {
        asset = _fetchResult[indexPath.row];
    } else {
        PHFetchResult *moment = [PHAsset fetchAssetsInAssetCollection:_fetchResult[indexPath.section] options:nil];
        asset = moment[indexPath.row];
    }
    
    TNKAssetViewController *next = [[TNKAssetViewController alloc] init];
    next.view.backgroundColor = [UIColor clearColor];
    next.view.frame = self.view.bounds;
    objc_setAssociatedObject(next, @selector(indexPath), indexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    next.selectButton.alpha = _fullscreen ? 0.0 : 1.0;
    [next.selectButton addTarget:self action:@selector(toggleSelection:) forControlEvents:UIControlEventTouchUpInside];
    next.selectButton.selected = [self.assetDelegate assetsDetailViewController:self isAssetSelectedAtIndexPath:indexPath];
    objc_setAssociatedObject(next.selectButton, @selector(indexPath), indexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    next.asset = asset;
    
    return next;
}

- (void)showAssetAtIndexPath:(NSIndexPath *)indexPath
{
    TNKAssetViewController *next = [self _assetViewControllerWithAssetAtIndexPath:indexPath];
    [self setViewControllers:@[next] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    [self _updateTitle];
}


#pragma mark - UIPageViewControllerDelegate

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(TNKAssetViewController *)last
{
    NSIndexPath *lastIndexPath = objc_getAssociatedObject(last, @selector(indexPath));
    NSIndexPath *nextIndexPath = nil;
    
    if (self.assetCollection == nil) {
        if (lastIndexPath.item > 0) {
            nextIndexPath = [NSIndexPath indexPathForItem:lastIndexPath.item - 1 inSection:lastIndexPath.section];
        } else if (lastIndexPath.section > 0) {
            NSInteger section = lastIndexPath.section - 1;
            
            PHFetchResult *moment = [PHAsset fetchAssetsInAssetCollection:_fetchResult[section] options:nil];
            
            nextIndexPath = [NSIndexPath indexPathForItem:moment.count - 1 inSection:section];
        }
    } else {
        if (lastIndexPath.item > 0) {
            nextIndexPath = [NSIndexPath indexPathForItem:lastIndexPath.item - 1 inSection:0];
        }
    }
    
    
    if (nextIndexPath != nil) {
        return [self _assetViewControllerWithAssetAtIndexPath:nextIndexPath];
    }
    
    return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(TNKAssetViewController *)last {
    NSIndexPath *lastIndexPath = objc_getAssociatedObject(last, @selector(indexPath));
    NSIndexPath *nextIndexPath = nil;
    
    if (self.assetCollection == nil) {
        PHFetchResult *moment = [PHAsset fetchAssetsInAssetCollection:_fetchResult[lastIndexPath.section] options:nil];
        
        if (lastIndexPath.item + 1 < moment.count) {
            nextIndexPath = [NSIndexPath indexPathForItem:lastIndexPath.item + 1 inSection:lastIndexPath.section];
        } else if (lastIndexPath.section + 1 < _fetchResult.count) {
            NSInteger section = lastIndexPath.section + 1;
            
            nextIndexPath = [NSIndexPath indexPathForItem:0 inSection:section];
        }
    } else {
        if (lastIndexPath.item + 1 < _fetchResult.count) {
            nextIndexPath = [NSIndexPath indexPathForItem:lastIndexPath.item + 1 inSection:0];
        }
    }
    
    
    if (nextIndexPath != nil) {
        return [self _assetViewControllerWithAssetAtIndexPath:nextIndexPath];
    }
    
    return nil;
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers {
    for (TNKAssetViewController *viewController in pendingViewControllers) {
        viewController.selectButton.alpha = _fullscreen ? 0.0 : 1.0;
    }
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    [self _updateTitle];
}


#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end