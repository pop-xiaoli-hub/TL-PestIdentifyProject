#import <XCTest/XCTest.h>
#import "TLWAIGestureCoordinator.h"

@interface TLWAIGestureCoordinator (RelayFixture)
- (void)tl_innerPan:(UIPanGestureRecognizer *)pan;
@end
@interface TLWRelayFixturePan : UIPanGestureRecognizer
@property (nonatomic) UIGestureRecognizerState fixtureState;
@property (nonatomic) CGFloat fixtureTranslation;
@end
@implementation TLWRelayFixturePan
- (UIGestureRecognizerState)state { return self.fixtureState; }
- (CGPoint)translationInView:(UIView *)view { return CGPointMake(0, self.fixtureTranslation); }
@end
@interface TLWRelayFixtureText : TLWAIRelayTextView
@property (nonatomic, strong) TLWRelayFixturePan *fixturePan;
@end
@implementation TLWRelayFixtureText
- (UIPanGestureRecognizer *)panGestureRecognizer { return self.fixturePan ?: super.panGestureRecognizer; }
- (CGSize)contentSize { return CGSizeMake(200, 300); }
@end
@interface TLWRelayFixtureTable : TLWAIRelayTableView @end
@implementation TLWRelayFixtureTable
- (CGSize)contentSize { return CGSizeMake(200, 1600); }
@end
@interface TLWAIGestureCoordinatorTests : XCTestCase @end
@implementation TLWAIGestureCoordinatorTests
- (void)testPopYieldsOnlyToScrollableHorizontalDirection {
    UIScrollView *strip = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
    strip.contentSize = CGSizeMake(500, 100);
    UIView *image = [[UIView alloc] initWithFrame:strip.bounds]; [strip addSubview:image];
    XCTAssertTrue([TLWAIGestureCoordinator shouldBlockPopForView:image velocity:CGPointMake(-100, 0)]);
    XCTAssertFalse([TLWAIGestureCoordinator shouldBlockPopForView:image velocity:CGPointMake(100, 0)]);
    strip.contentOffset = CGPointMake(100, 0);
    XCTAssertTrue([TLWAIGestureCoordinator shouldBlockPopForView:image velocity:CGPointMake(100, 0)]);
    XCTAssertFalse([TLWAIGestureCoordinator shouldBlockPopForView:image velocity:CGPointMake(100, 200)]);
    XCTAssertFalse([TLWAIGestureCoordinator shouldBlockPopForView:[UIView new] velocity:CGPointMake(100, 0)]);
}
- (void)testRegisteredNativePansCanRelayWithoutReplacingTheirDelegates {
    TLWAIRelayTextView *inner = [[TLWAIRelayTextView alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
    TLWAIRelayTableView *outer = [[TLWAIRelayTableView alloc] initWithFrame:CGRectMake(0, 0, 200, 400) style:UITableViewStylePlain];
    id innerDelegate = inner.panGestureRecognizer.delegate, outerDelegate = outer.panGestureRecognizer.delegate;
    TLWAIGestureCoordinator *coordinator = [TLWAIGestureCoordinator new];
    [coordinator registerTextView:inner outerTable:outer];
    XCTAssertTrue([coordinator allowsSimultaneous:inner.panGestureRecognizer other:outer.panGestureRecognizer]);
    XCTAssertEqual(inner.panGestureRecognizer.delegate, innerDelegate);
    XCTAssertEqual(outer.panGestureRecognizer.delegate, outerDelegate);
    inner.text = @"selected"; inner.selectedRange = NSMakeRange(0, 4);
    XCTAssertFalse([coordinator allowsSimultaneous:inner.panGestureRecognizer other:outer.panGestureRecognizer]);
    [coordinator uninstall];
    XCTAssertFalse([coordinator allowsSimultaneous:inner.panGestureRecognizer other:outer.panGestureRecognizer]);
}

- (void)testReversingAfterInnerBoundaryImmediatelyReturnsConsumptionToInner {
    TLWRelayFixtureText *inner = [[TLWRelayFixtureText alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    TLWRelayFixtureTable *outer = [[TLWRelayFixtureTable alloc] initWithFrame:CGRectMake(0, 0, 200, 600) style:UITableViewStylePlain];
    TLWRelayFixturePan *pan = [TLWRelayFixturePan new];
    inner.fixturePan = pan;
    [inner addGestureRecognizer:pan];
    inner.contentOffset = CGPointMake(0, 80);
    outer.contentOffset = CGPointMake(0, 400);
    TLWAIGestureCoordinator *coordinator = [TLWAIGestureCoordinator new];
    [coordinator registerTextView:inner outerTable:outer];
    pan.fixtureState = UIGestureRecognizerStateBegan;
    [coordinator tl_innerPan:pan];
    pan.fixtureState = UIGestureRecognizerStateChanged;
    pan.fixtureTranslation = -100;
    [coordinator tl_innerPan:pan];
    XCTAssertEqualWithAccuracy(inner.contentOffset.y, 100, 0.01);
    XCTAssertEqualWithAccuracy(outer.contentOffset.y, 480, 0.01);
    pan.fixtureTranslation = -90;
    [coordinator tl_innerPan:pan];
    XCTAssertEqualWithAccuracy(inner.contentOffset.y, 90, 0.01);
    XCTAssertEqualWithAccuracy(outer.contentOffset.y, 480, 0.01);
    [coordinator correctRelayOffsets];
    XCTAssertEqualWithAccuracy(inner.contentOffset.y, 90, 0.01);
    XCTAssertEqualWithAccuracy(outer.contentOffset.y, 480, 0.01);
    [coordinator uninstall];
}
@end
