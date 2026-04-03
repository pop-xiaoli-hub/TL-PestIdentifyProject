#import "TLWAIAssistantSystemMessageCell.h"
#import "TLWAIAssistantMessage.h"
#import <Masonry/Masonry.h>

static CGFloat const kSystemMessageVerticalInset = 6.0;

@interface TLWAIAssistantSystemMessageCell ()
@property (nonatomic, strong) UILabel *tipLabel;
@end

@implementation TLWAIAssistantSystemMessageCell

+ (NSString *)reuseIdentifier {
    return @"TLWAIAssistantSystemMessageCell";
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        self.tipLabel = [[UILabel alloc] init];
        self.tipLabel.numberOfLines = 0;
        self.tipLabel.textAlignment = NSTextAlignmentCenter;
        self.tipLabel.textColor = [UIColor colorWithWhite:0.36 alpha:1.0];
        self.tipLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        self.tipLabel.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.45];
        self.tipLabel.layer.cornerRadius = 12;
        self.tipLabel.layer.masksToBounds = YES;
        [self.contentView addSubview:self.tipLabel];
        [self.tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView).offset(kSystemMessageVerticalInset);
            make.bottom.equalTo(self.contentView).offset(-kSystemMessageVerticalInset);
            make.centerX.equalTo(self.contentView);
            make.width.lessThanOrEqualTo(self.contentView.mas_width).multipliedBy(0.9);
        }];
    }
    return self;
}

- (void)configureWithMessage:(TLWAIAssistantMessage *)message {
    // 系统消息只承接提示语，不参与左右气泡对齐逻辑。
    self.tipLabel.text = message.text;
}

@end
