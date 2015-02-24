//
//  TNKImagePickerController.m
//  Pods
//
//  Created by David Beck on 2/21/15.
//
//

#import "TNKImagePickerController.h"

@import Photos;

#import "TNKImagePickerControllerBundle.h"
#import "TNKCollectionsTitleButton.h"
#import "TNKCollectionPickerController.h"
#import "TNKAssetCell.h"
#import "TNKAssetImageView.h"
#import "TNKMomentHeaderView.h"
#import "TNKCollectionViewFloatingHeaderFlowLayout.h"


#define TNKObjectSpacing 5.0


@interface TNKImagePickerController () <UIPopoverPresentationControllerDelegate, TNKCollectionPickerControllerDelegate>
{
    UIButton *_collectionButton;
    PHFetchResult *_fetchResult;
    PHFetchResult *_moments;
    NSCache *_momentCache;
    BOOL _windowLoaded;
}

@end

@implementation TNKImagePickerController

#pragma mark - Properties

- (void)setAssetCollection:(PHAssetCollection *)assetCollection {
    _assetCollection = assetCollection;
    
    [self _updateForAssetCollection];
}

- (void)_updateForAssetCollection
{
    if (_assetCollection == nil) {
        self.title = NSLocalizedString(@"Moments", nil);
    } else {
        self.title = _assetCollection.localizedTitle;
    }
    [_collectionButton setTitle:self.title forState:UIControlStateNormal];
    [_collectionButton sizeToFit];
    
    
    if (_assetCollection != nil) {
        _fetchResult = [PHAsset fetchAssetsInAssetCollection:_assetCollection options:nil];
        _moments = nil;
    } else {
        _fetchResult = nil;
        _moments = [PHAssetCollection fetchMomentsWithOptions:nil];
    }
    
    if (self.isViewLoaded) {
        [self.collectionView reloadData];
        
        if (_moments != nil) {
            [self.collectionView layoutIfNeeded];
            [self _scrollToBottomAnimated:NO];
        }
    }
}


#pragma mark - Initialization

- (void)_init
{
    _cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    self.navigationItem.leftBarButtonItem = _cancelButton;
    
    _doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Select", nil) style:UIBarButtonItemStyleDone target:self action:@selector(done:)];
    _doneButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = _doneButton;
    
    _collectionButton = [TNKCollectionsTitleButton buttonWithType:UIButtonTypeSystem];
    [_collectionButton addTarget:self action:@selector(changeCollection:) forControlEvents:UIControlEventTouchUpInside];
    _collectionButton.titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
    _collectionButton.imageEdgeInsets = UIEdgeInsetsMake(0.0, 3.0, 0.0, 0.0);
    [_collectionButton setImage:[TNKImagePickerControllerImageNamed(@"nav-disclosure") imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [_collectionButton sizeToFit];
    self.navigationItem.titleView = _collectionButton;
    
    _momentCache = [[NSCache alloc] init];
    [self _updateForAssetCollection];
}

- (instancetype)init
{
    UICollectionViewFlowLayout *layout = [[TNKCollectionViewFloatingHeaderFlowLayout alloc] init];
    layout.minimumLineSpacing = TNKObjectSpacing;
    layout.minimumInteritemSpacing = 0.0;
    layout.sectionInset = UIEdgeInsetsMake(0.0, 0.0, 10.0, 0.0);
    return [self initWithCollectionViewLayout:layout];
}

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithCollectionViewLayout:layout];
    if (self) {
        [self _init];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _init];
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.collectionView registerClass:[TNKAssetCell class] forCellWithReuseIdentifier:@"Cell"];
    self.collectionView.alwaysBounceVertical = YES;
    
    [self.collectionView registerClass:[TNKMomentHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
}

- (void)viewDidLayoutSubviews
{
    if (self.view.window && !_windowLoaded) {
        _windowLoaded = YES;
        
        [self.collectionView reloadData];
        
        if (_moments != nil) {
            [self.collectionView layoutIfNeeded];
            [self _scrollToBottomAnimated:NO];
        }
    }
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    [super didMoveToParentViewController:parent];
    
    UIFont *font = self.navigationController.navigationBar.titleTextAttributes[NSFontAttributeName];
    if (font != nil) {
        _collectionButton.titleLabel.font = font;
        [_collectionButton sizeToFit];
    }
}


#pragma mark - Actions

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)changeCollection:(id)sender {
    TNKCollectionPickerController *collectionPicker = [[TNKCollectionPickerController alloc] init];
    collectionPicker.delegate = self;
    
    collectionPicker.modalPresentationStyle = UIModalPresentationPopover;
    collectionPicker.popoverPresentationController.sourceView = _collectionButton;
    collectionPicker.popoverPresentationController.sourceRect = _collectionButton.bounds;
    collectionPicker.popoverPresentationController.delegate = self;
    [self presentViewController:collectionPicker animated:YES completion:nil];
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (_moments != nil) {
        return _moments.count;
    } else {
        return 1;
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (_moments != nil) {
        PHAssetCollection *collection = _moments[section];
        return collection.estimatedAssetCount;
    } else {
        return _fetchResult.count;
    }
}

- (PHFetchResult *)_assetsForMoment:(PHAssetCollection *)collection
{
    PHFetchResult *result = [_momentCache objectForKey:collection.localIdentifier];
    if (result == nil) {
        PHFetchOptions *options = [PHFetchOptions new];
        options.includeAllBurstAssets = NO;
        result = [PHAsset fetchAssetsInAssetCollection:collection options:options];
        [_momentCache setObject:result forKey:collection.localIdentifier];
    }
    
    return result;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TNKAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    PHAsset *asset = nil;
    if (_moments != nil) {
        PHAssetCollection *collection = _moments[indexPath.section];
        PHFetchResult *fetchResult = [self _assetsForMoment:collection];
        asset = fetchResult[indexPath.row];
    } else {
        asset = _fetchResult[indexPath.row];
    }
    
    cell.backgroundColor = [UIColor redColor];
    cell.imageView.asset = asset;
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger columns = floor(collectionView.bounds.size.width / 80.0);
    CGFloat width = floor((collectionView.bounds.size.width + TNKObjectSpacing) / columns) - TNKObjectSpacing;
    
    return CGSizeMake(width, width);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    TNKMomentHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
    
    if (_moments != nil) {
        PHAssetCollection *collection = _moments[indexPath.section];
        
        static NSDateFormatter *dateFormatter = nil;
        static NSDateFormatter *comparisonFormatter = nil;
        static NSDateFormatter *weekdayFormatter = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            dateFormatter = [NSDateFormatter new];
            dateFormatter.dateStyle = NSDateFormatterMediumStyle;
            dateFormatter.timeStyle = NSDateFormatterNoStyle;
            dateFormatter.doesRelativeDateFormatting = YES;
            
            comparisonFormatter = [NSDateFormatter new];
            comparisonFormatter.dateStyle = NSDateFormatterMediumStyle;
            comparisonFormatter.timeStyle = NSDateFormatterNoStyle;
            
            weekdayFormatter = [NSDateFormatter new];
            weekdayFormatter.dateFormat = @"EEEE";
        });
        
        NSDate *date = collection.startDate;
        NSString *dateString = nil;
        NSString *relativeString = [dateFormatter stringFromDate:date];
        NSString *absoluteString = [comparisonFormatter stringFromDate:date];
        
        if (![relativeString isEqual:absoluteString]) {
            dateString = relativeString;
        } else if (-date.timeIntervalSinceNow < 60.0 * 60.0 * 24.0 * 7.0) {
            dateString = [weekdayFormatter stringFromDate:date];
        } else {
            dateString = relativeString;
        }
        
        
        if (collection.localizedTitle != nil) {
            headerView.primaryLabel.text = collection.localizedTitle;
            headerView.secondaryLabel.text = [collection.localizedLocationNames componentsJoinedByString:@" & "];
            headerView.detailLabel.text = dateString;
        } else {
            headerView.primaryLabel.text = dateString;
            headerView.secondaryLabel.text = nil;
            headerView.detailLabel.text = nil;
        }
    }
    
    return headerView;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (_moments != nil) {
        return CGSizeMake(collectionView.bounds.size.width, 44.0);
    } else {
        return CGSizeZero;
    }
}

- (void)_scrollToBottomAnimated:(BOOL)animated
{
    CGPoint contentOffset = self.collectionView.contentOffset;
    contentOffset.y = self.collectionView.contentSize.height - self.collectionView.bounds.size.height + self.collectionView.contentInset.bottom;
    contentOffset.y = MAX(contentOffset.y, -self.collectionView.contentInset.top);
    contentOffset.y = MAX(self.collectionView.contentSize.height - self.collectionView.bounds.size.height + self.collectionView.contentInset.bottom, -self.collectionView.contentInset.top);
    [self.collectionView setContentOffset:contentOffset animated:animated];
}


#pragma mark - TNKCollectionPickerControllerDelegate

- (void)collectionPicker:(TNKCollectionPickerController *)collectionPicker didSelectCollection:(PHAssetCollection *)collection {
    self.assetCollection = collection;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UIPopoverPresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

@end
