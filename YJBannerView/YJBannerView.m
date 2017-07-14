//
//  YJBannerView.m
//  YJBannerViewDemo
//
//  Created by YJHou on 2014/5/24.
//  Copyright © 2014年 地址:https://github.com/YJManager/YJBannerViewOC . All rights reserved.
//

#import "YJBannerView.h"
#import "YJBannerViewCell.h"
#import "UIView+YJBannerViewExt.h"
#import "YJHollowPageControl.h"

static NSString *const bannerViewCellId = @"YJBannerView";
#define kPageControlDotDefaultSize CGSizeMake(8, 8)

@interface YJBannerView () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, weak) UICollectionViewFlowLayout *flowLayout;     /**< 流程控制 */
@property (nonatomic, weak) UICollectionView *collectionView;           /**< 主视图 */
@property (nonatomic, weak) UIControl *pageControl;                     /**< 分页指示器 */
@property (nonatomic, weak) NSTimer *timer;                             /**< 定时器 */
@property (nonatomic, assign) NSInteger totalItemsCount;                /**< 数量 */
@property (nonatomic, strong) UIImageView *backgroundImageView;         /**< 数据为空时的背景图 */
@property (nonatomic, copy) NSString *setImageViewPlaceholderString;    /**< 自定义设置网络和默认图片的方法 */
@property (nonatomic, copy) NSString *placeholderImageName;

@end

@implementation YJBannerView

+ (YJBannerView *)bannerViewWithFrame:(CGRect)frame dataSource:(id<YJBannerViewDataSource>)dataSource delegate:(id<YJBannerViewDelegate>)delegate selectorString:(NSString *)selectorString placeholderImageName:(NSString *)placeholderImageName{
    
    YJBannerView *bannerView = [[YJBannerView alloc] initWithFrame:frame];
    bannerView.dataSource = dataSource;
    bannerView.delegate = delegate;
    bannerView.setImageViewPlaceholderString = selectorString;
    if (placeholderImageName) {
        bannerView.placeholderImageName = placeholderImageName;
    }
    return bannerView;
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self _initSetting];
        [self _setupBannerMainView];
    }
    return self;
}

- (void)awakeFromNib{
    [super awakeFromNib];
    [self _initSetting];
    [self _setupBannerMainView];
}

/** 初始化默认设置 */
- (void)_initSetting{
    
    self.backgroundColor = [UIColor whiteColor];
    _autoDuration = 3.0;
    _autoScroll = YES;
    _pageControlStyle = PageControlSystem;
    _pageControlAliment = PageControlAlimentCenter;
    _pageControlDotSize = kPageControlDotDefaultSize;
    _pageControlBottomMargin = 10.0f;
    _pageControlHorizontalEdgeMargin = 10.0f;
    _pageControlNormalColor = [UIColor lightGrayColor];
    _pageControlHighlightColor = [UIColor whiteColor];
    _bannerImageViewContentMode = UIViewContentModeScaleToFill;
    
    _titleFont = [UIFont systemFontOfSize:14.0f];
    _titleTextColor = [UIColor whiteColor];
    _titleBackgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]; // 黑0.5
    _titleHeight = 30.0f;
    _titleEdgeMargin = 10.0f;
    _titleAlignment = NSTextAlignmentLeft;
}

#pragma mark - register Custom Cell
- (void)setDataSource:(id<YJBannerViewDataSource>)dataSource{
    _dataSource = dataSource;
    
    if (dataSource && [dataSource respondsToSelector:@selector(bannerViewCustomCellClass:)] && [dataSource bannerViewCustomCellClass:self]) {
        [self.collectionView registerClass:[dataSource bannerViewCustomCellClass:self] forCellWithReuseIdentifier:bannerViewCellId];
    }
}

#pragma mark - Setter && Getter
- (void)setPlaceholderImageName:(NSString *)placeholderImageName{
    _placeholderImageName = placeholderImageName;
    self.backgroundImageView.image = [UIImage imageNamed:placeholderImageName];
}

- (void)setPageControlDotSize:(CGSize)pageControlDotSize{
    
    _pageControlDotSize = pageControlDotSize;
    
    [self _setupPageControl];
    if ([self.pageControl isKindOfClass:[YJHollowPageControl class]]) {
        YJHollowPageControl *pageContol = (YJHollowPageControl *)_pageControl;
        pageContol.dotSize = pageControlDotSize;
    }
}

- (void)setPageControlStyle:(PageControlStyle)pageControlStyle{
    
    _pageControlStyle = pageControlStyle;
    
    [self _setupPageControl];
}

- (void)setPageControlNormalColor:(UIColor *)pageControlNormalColor{
    
    _pageControlNormalColor = pageControlNormalColor;
    
    if ([self.pageControl isKindOfClass:[YJHollowPageControl class]]) {
        YJHollowPageControl *pageControl = (YJHollowPageControl *)_pageControl;
        pageControl.dotColor = pageControlNormalColor;
    }else if ([self.pageControl isKindOfClass:[UIPageControl class]]) {
        UIPageControl *pageControl = (UIPageControl *)_pageControl;
        pageControl.pageIndicatorTintColor = pageControlNormalColor;
    }
}

- (void)setPageControlHighlightColor:(UIColor *)pageControlHighlightColor{
    
    _pageControlHighlightColor = pageControlHighlightColor;
    
    if ([self.pageControl isKindOfClass:[YJHollowPageControl class]]) {
        YJHollowPageControl *pageControl = (YJHollowPageControl *)_pageControl;
        pageControl.currentDotColor = pageControlHighlightColor;
    } else if ([self.pageControl isKindOfClass:[UIPageControl class]]){
        UIPageControl *pageControl = (UIPageControl *)_pageControl;
        pageControl.currentPageIndicatorTintColor = pageControlHighlightColor;
    }
}

- (void)setPageControlNormalImage:(UIImage *)pageControlNormalImage{
    
    _pageControlNormalImage = pageControlNormalImage;
    
    if (self.pageControlStyle != PageControlAnimated) {
        self.pageControlStyle = PageControlAnimated;
    }
    [self setCustomPageControlDotImage:pageControlNormalImage isCurrentPageDot:NO];
}

- (void)setPageControlHighlightImage:(UIImage *)pageControlHighlightImage{
    
    _pageControlHighlightImage = pageControlHighlightImage;
    
    if (self.pageControlStyle != PageControlAnimated) {
        self.pageControlStyle = PageControlAnimated;
    }
    [self setCustomPageControlDotImage:pageControlHighlightImage isCurrentPageDot:YES];
}

- (void)setCustomPageControlDotImage:(UIImage *)image isCurrentPageDot:(BOOL)isCurrentPageDot{
    
    if (!image || !self.pageControl) return;
    
    if ([self.pageControl isKindOfClass:[YJHollowPageControl class]]) {
        YJHollowPageControl *pageControl = (YJHollowPageControl *)_pageControl;
        if (isCurrentPageDot) {
            pageControl.currentDotImage = image;
        } else {
            pageControl.dotImage = image;
        }
    }
}

- (void)setAutoScroll:(BOOL)autoScroll{
    
    _autoScroll = autoScroll;
    
    [self invalidateTimer];
    
    if (autoScroll) {
        [self _setupTimer];
    }
}

-(void)setBannerViewScrollDirection:(BannerViewDirection)bannerViewScrollDirection{

    _bannerViewScrollDirection = bannerViewScrollDirection;
    
    if (bannerViewScrollDirection == BannerViewDirectionLeft || bannerViewScrollDirection == BannerViewDirectionRight) {
        _flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }else if (bannerViewScrollDirection == BannerViewDirectionTop || bannerViewScrollDirection == BannerViewDirectionBottom){
        _flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    }
}

- (void)setAutoDuration:(CGFloat)autoDuration{
    
    _autoDuration = autoDuration;
    
    [self setAutoScroll:self.autoScroll];
}

#pragma mark - Lazy
- (UIImageView *)backgroundImageView{
    if (!_backgroundImageView) {
        _backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _backgroundImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self insertSubview:_backgroundImageView belowSubview:self.collectionView];
    }
    return _backgroundImageView;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    self.dataSource = self.dataSource;
    [super layoutSubviews];
    
    _flowLayout.itemSize = self.frame.size;
    
    _collectionView.frame = self.bounds;
    
    if (_collectionView.contentOffset.x == 0 &&  _totalItemsCount) {
        int targetIndex = 0;
        targetIndex = _totalItemsCount * 0.5;
        [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:targetIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
    }
    
    CGSize size = CGSizeZero;
    
    if ([self.pageControl isKindOfClass:[YJHollowPageControl class]]) {
        
        YJHollowPageControl *pageControl = (YJHollowPageControl *)_pageControl;
        
        if (!(self.pageControlNormalImage && self.pageControlHighlightImage && CGSizeEqualToSize(kPageControlDotDefaultSize, self.pageControlDotSize))) {
            pageControl.dotSize = self.pageControlDotSize;
        }
        
        size = [pageControl sizeForNumberOfPages:[self _imageDataSources].count];
    } else {
        size = CGSizeMake([self _imageDataSources].count * self.pageControlDotSize.width * 1.5, self.pageControlDotSize.height);
    }
    CGFloat x = (self.width_bannerView - size.width) * 0.5;
    if (self.pageControlAliment == PageControlAlimentLeft) { // 靠左
        
        x = 0.0f;
        
    }else if (self.pageControlAliment == PageControlAlimentCenter){ // 居中
    
    }else if (self.pageControlAliment == PageControlAlimentRight){ // 靠右
        
        x = self.collectionView.width_bannerView - size.width;
        
    }
    
    CGFloat y = self.collectionView.height_bannerView - size.height;
    
    if ([self.pageControl isKindOfClass:[YJHollowPageControl class]]) {
        
        YJHollowPageControl *pageControl = (YJHollowPageControl *)_pageControl;
        [pageControl sizeToFit];
    }
    
    CGRect pageControlFrame = CGRectMake(x, y, size.width, size.height);
    if (self.pageControlAliment == PageControlAlimentLeft) {
        pageControlFrame.origin.x += self.pageControlHorizontalEdgeMargin;
    }else if (self.pageControlAliment == PageControlAlimentRight){
        pageControlFrame.origin.x -= self.pageControlHorizontalEdgeMargin;
    }
    pageControlFrame.origin.y -= self.pageControlBottomMargin;
    self.pageControl.frame = pageControlFrame;
    
    self.pageControl.hidden = self.pageControlStyle == PageControlNone;
    
    if (self.backgroundImageView) {
        self.backgroundImageView.frame = self.bounds;
    }
}

#pragma mark - 解决兼容优化问题
- (void)willMoveToSuperview:(UIView *)newSuperview{
    
    if (!newSuperview) {
        [self invalidateTimer];
    }
}

- (void)dealloc {
    _collectionView.delegate = nil;
    _collectionView.dataSource = nil;
}

- (void)adjustBannerViewWhenViewWillAppear{
    
    long targetIndex = [self _currentIndex];
    if (targetIndex < _totalItemsCount) {
        [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:targetIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
    }
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return _totalItemsCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    YJBannerViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:bannerViewCellId forIndexPath:indexPath];
    long itemIndex = [self _pageControlIndexWithCurrentCellIndex:indexPath.item];
    
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(bannerView:customCell:index:)] && [self.dataSource respondsToSelector:@selector(bannerViewCustomCellClass:)] && [self.dataSource bannerViewCustomCellClass:self]) {
        [self.dataSource bannerView:self customCell:cell index:itemIndex];
        return cell;
    }
    
    NSString *imagePath = (itemIndex < [self _imageDataSources].count)?[self _imageDataSources][itemIndex]:nil;
    NSString *title = (itemIndex < [self _titlesDataSources].count)?[self _titlesDataSources][itemIndex]:nil;
    
    if (!cell.isConfigured) {
        cell.titleLabelBackgroundColor = self.titleBackgroundColor;
        cell.titleLabelHeight = self.titleHeight;
        cell.titleLabelEdgeMargin = self.titleEdgeMargin;
        cell.titleLabelTextAlignment = self.titleAlignment;
        cell.titleLabelTextColor = self.titleTextColor;
        cell.titleLabelTextFont = self.titleFont;
        cell.isConfigured = YES;
        cell.showImageViewContentMode = self.bannerImageViewContentMode;
        cell.clipsToBounds = YES;
    }
    
    [cell cellWithSelectorString:self.setImageViewPlaceholderString imagePath:imagePath placeholderImageName:self.placeholderImageName title:title];

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (self.delegate && [self.delegate respondsToSelector:@selector(bannerView:didSelectItemAtIndex:)]) {
        [self.delegate bannerView:self didSelectItemAtIndex:[self _pageControlIndexWithCurrentCellIndex:indexPath.item]];
    }
    if (self.didSelectItemAtIndexBlock) {
        self.didSelectItemAtIndexBlock([self _pageControlIndexWithCurrentCellIndex:indexPath.item]);
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (![self _imageDataSources].count) return; // 解决清除timer时偶尔会出现的问题
    int itemIndex = [self _currentIndex];
    int indexOnPageControl = [self _pageControlIndexWithCurrentCellIndex:itemIndex];
    
    if ([self.pageControl isKindOfClass:[YJHollowPageControl class]]) {
        YJHollowPageControl *pageControl = (YJHollowPageControl *)_pageControl;
        pageControl.currentPage = indexOnPageControl;
    } else {
        UIPageControl *pageControl = (UIPageControl *)_pageControl;
        pageControl.currentPage = indexOnPageControl;
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    if (self.autoScroll) {
        [self invalidateTimer];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (self.autoScroll) {
        [self _setupTimer];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self scrollViewDidEndScrollingAnimation:self.collectionView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
    if (![self _imageDataSources].count) return; // 解决清除timer时偶尔会出现的问题
    int itemIndex = [self _currentIndex];
    int indexOnPageControl = [self _pageControlIndexWithCurrentCellIndex:itemIndex];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(bannerView:didScroll2Index:)]) {
        [self.delegate bannerView:self didScroll2Index:indexOnPageControl];
    }
    if (self.didScroll2IndexBlock) {
        self.didScroll2IndexBlock(indexOnPageControl);
    }
}

#pragma mark - 私有功能方法
/** 安装主视图 */
- (void)_setupBannerMainView{
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumLineSpacing = 0.0f;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _flowLayout = flowLayout;
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:flowLayout];
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.pagingEnabled = YES;
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.showsVerticalScrollIndicator = NO;
    [collectionView registerClass:[YJBannerViewCell class] forCellWithReuseIdentifier:bannerViewCellId];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.scrollsToTop = NO;
    [self addSubview:collectionView];
    _collectionView = collectionView;
}
/** 安装PageControl */
- (void)_setupPageControl{
    
    if (_pageControl) [_pageControl removeFromSuperview];
    
    if ([self _imageDataSources].count == 0) {return;}
    
    if ([self _imageDataSources].count == 1) {return;}
    
    int indexOnPageControl = [self _pageControlIndexWithCurrentCellIndex:[self _currentIndex]];
    
    switch (self.pageControlStyle) {
        case PageControlNone:{
            break;
        }
        case PageControlSystem:{
            UIPageControl *pageControl = [[UIPageControl alloc] init];
            pageControl.numberOfPages = [self _imageDataSources].count;
            pageControl.currentPageIndicatorTintColor = self.pageControlHighlightColor;
            pageControl.pageIndicatorTintColor = self.pageControlNormalColor;
            pageControl.userInteractionEnabled = NO;
            pageControl.currentPage = indexOnPageControl;
            [self addSubview:pageControl];
            _pageControl = pageControl;
            break;
        }
        case PageControlAnimated:{
            YJHollowPageControl *pageControl = [[YJHollowPageControl alloc] init];
            pageControl.numberOfPages = [self _imageDataSources].count;
            pageControl.dotColor = self.pageControlNormalColor;
            pageControl.currentDotColor = self.pageControlHighlightColor;
            pageControl.userInteractionEnabled = NO;
            pageControl.resizeScale = 1.0;
            pageControl.spacing = 5.0f;
            pageControl.currentPage = indexOnPageControl;
            [self addSubview:pageControl];
            _pageControl = pageControl;
            break;
        }
        case PageControlCustom:{
        
        }
        default:
            break;
    }

    if (self.pageControlNormalImage) {
        self.pageControlNormalImage = self.pageControlNormalImage;
    }
    
    if (self.pageControlHighlightImage) {
        self.pageControlHighlightImage = self.pageControlHighlightImage;
    }
}

/** 安装定时器 */
- (void)_setupTimer{
    
    [self invalidateTimer];
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:self.autoDuration target:self selector:@selector(automaticScrollAction) userInfo:nil repeats:YES];
    _timer = timer;
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

/** 停止定时器 */
- (void)invalidateTimer{
    
    [_timer invalidate];
    _timer = nil;
}

- (void)automaticScrollAction{
    
    if (_totalItemsCount == 0) return;
    int currentIndex = [self _currentIndex];
    if (self.bannerViewScrollDirection == BannerViewDirectionLeft || self.bannerViewScrollDirection == BannerViewDirectionTop) {
        [self _scrollToIndex:currentIndex + 1];
    }else if (self.bannerViewScrollDirection == BannerViewDirectionRight || self.bannerViewScrollDirection == BannerViewDirectionBottom){
        [self _scrollToIndex:currentIndex - 1];
    }
}

- (void)_scrollToIndex:(int)targetIndex{
    
    if (targetIndex >= _totalItemsCount) {
        targetIndex = _totalItemsCount * 0.5;
        [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:targetIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
    }else{
        [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:targetIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
    }
}

/** 当前的页数 */
- (int)_currentIndex{
    
    if (_collectionView.width_bannerView == 0 || _collectionView.height_bannerView == 0) {return 0;}
    int index = 0;
    if (_flowLayout.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        index = (_collectionView.contentOffset.x + _flowLayout.itemSize.width * 0.5) / _flowLayout.itemSize.width;
    } else {
        index = (_collectionView.contentOffset.y + _flowLayout.itemSize.height * 0.5) / _flowLayout.itemSize.height;
    }
    return MAX(0, index);
}

- (int)_pageControlIndexWithCurrentCellIndex:(NSInteger)index{
    return (int)index % [self _imageDataSources].count;
}

/** 显示图片的数组 */
- (NSArray *)_imageDataSources{
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(bannerViewImages:)]) {
        return [self.dataSource bannerViewImages:self];
    }
    return @[];
}

/** 显示的标题数组 */
- (NSArray *)_titlesDataSources{
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(bannerViewTitles:)]) {
        NSArray *titles = [self.dataSource bannerViewTitles:self];
        return titles;
    }
    return @[];
}

#pragma mark - 刷新数据
- (void)reloadData{
    
    [self invalidateTimer];
    
    _totalItemsCount = [self _imageDataSources].count * 1000;
    
    if ([self _imageDataSources].count > 1) {
        self.collectionView.scrollEnabled = YES;
        [self setAutoScroll:self.autoScroll];
    } else {
        self.collectionView.scrollEnabled = NO;
        [self setAutoScroll:NO];
    }
    
    [self _setupPageControl];
    [self.collectionView reloadData];
}

@end
