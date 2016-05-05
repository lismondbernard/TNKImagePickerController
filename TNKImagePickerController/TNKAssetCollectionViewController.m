//
//  TNKAssetCollectionViewController.m
//  TNKImagePickerController
//
//  Created by David Beck on 5/5/16.
//  Copyright © 2016 Think Ultimate LLC. All rights reserved.
//

#import "TNKAssetCollectionViewController.h"
#import "TNKCollectionViewController_Private.h"

@import Photos;

#import "TNKCollectionsTitleButton.h"
#import "TNKCollectionPickerController.h"
#import "TNKAssetCell.h"
#import "TNKAssetImageView.h"
#import "TNKMomentHeaderView.h"
#import "TNKCollectionViewFloatingHeaderFlowLayout.h"
#import "TNKAssetsDetailViewController.h"
#import "NSDate+TNKFormattedDay.h"
#import "UIImage+TNKIcons.h"
#import "TNKAssetSelection.h"


@interface TNKAssetCollectionViewController ()

@end

@implementation TNKAssetCollectionViewController

#pragma mark - Initialization

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection
{
	self = [super init];
	if (self != nil) {
		_assetCollection = assetCollection;
		_fetchResult = [PHAsset fetchAssetsInAssetCollection:_assetCollection options:[self assetFetchOptions]];
	}
	
	return self;
}


#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	
}


#pragma mark - Asset Management

- (PHAsset *)assetAtIndexPath:(NSIndexPath *)indexPath {
	return _fetchResult[indexPath.row];
}

- (NSIndexPath *)indexPathForAsset:(PHAsset *)asset {
	NSUInteger item = [_fetchResult indexOfObject:asset];
	
	if (item != NSNotFound) {
		return [NSIndexPath indexPathForItem:item inSection:0];
	} else {
		return nil;
	}
}


#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return _fetchResult.count;
}


#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    dispatch_async(dispatch_get_main_queue(), ^{
		PHFetchResultChangeDetails *details = [changeInstance changeDetailsForFetchResult:_fetchResult];
		if (details != nil) {
			_fetchResult = [details fetchResultAfterChanges];
			
			if (details.hasIncrementalChanges) {
				[self.collectionView performBatchUpdates:^{
					NSMutableArray *removedIndexPaths = [NSMutableArray new];
					[details.removedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
						[removedIndexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
					}];
					[self.collectionView deleteItemsAtIndexPaths:removedIndexPaths];
					
					
					NSMutableArray *insertedIndexPaths = [NSMutableArray new];
					[details.insertedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
						[insertedIndexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
					}];
					[self.collectionView insertItemsAtIndexPaths:insertedIndexPaths];
					
					
					NSMutableArray *changedIndexPaths = [NSMutableArray new];
					[details.changedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
						[changedIndexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
					}];
					[self.collectionView reloadItemsAtIndexPaths:changedIndexPaths];
					
					
					[details enumerateMovesWithBlock:^(NSUInteger fromIndex, NSUInteger toIndex) {
						NSIndexPath *from = [NSIndexPath indexPathForRow:fromIndex inSection:0];
						NSIndexPath *to = [NSIndexPath indexPathForRow:fromIndex inSection:0];
						
						[self.collectionView moveItemAtIndexPath:from toIndexPath:to];
					}];
				} completion:nil];
			} else {
				[self.collectionView reloadData];
			}
		}
    });
}

@end