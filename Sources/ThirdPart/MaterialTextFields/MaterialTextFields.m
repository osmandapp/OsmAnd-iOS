#import "MaterialTextFields.h"

@interface MDCMultilineTextView : UITextView
@property(nonatomic, copy) void (^contentSizeDidChange)(CGSize size);
@end

@implementation MDCMultilineTextView

- (void)setContentSize:(CGSize)contentSize
{
    CGSize previousSize = self.contentSize;
    [super setContentSize:contentSize];
    if (!CGSizeEqualToSize(previousSize, contentSize) && self.contentSizeDidChange)
        self.contentSizeDidChange(contentSize);
}

- (CGSize)intrinsicContentSize
{
    CGSize fittingSize = [self sizeThatFits:CGSizeMake(CGRectGetWidth(self.bounds), CGFLOAT_MAX)];
    return CGSizeMake(UIViewNoIntrinsicMetric, MAX(44.0, fittingSize.height));
}

@end

@interface MDCMultilineTextField ()
@property(nonatomic, strong) MDCMultilineTextView *textView;
@property(nonatomic, strong) UIButton *clearButton;
@property(nonatomic, strong) UIView *underline;
@property(nonatomic, strong) UILabel *placeholderLabel;
@end

@implementation MDCMultilineTextField

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
        [self commonInit];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
        [self commonInit];
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)commonInit
{
    _textInsetsMode = MDCTextInputTextInsetsModeNever;
    _hidesPlaceholderOnInput = YES;

    _textView = [[MDCMultilineTextView alloc] initWithFrame:CGRectZero];
    _textView.translatesAutoresizingMaskIntoConstraints = NO;
    _textView.backgroundColor = UIColor.clearColor;
    _textView.scrollEnabled = NO;
    _textView.textContainerInset = UIEdgeInsetsZero;
    _textView.textContainer.lineFragmentPadding = 0.0;

    __weak __typeof__(self) weakSelf = self;
    _textView.contentSizeDidChange = ^(CGSize size) {
        [weakSelf textViewContentSizeDidChange:size];
    };

    _placeholderLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _placeholderLabel.numberOfLines = 1;

    _clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _clearButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_clearButton addTarget:self action:@selector(clearButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    _underline = [[UIView alloc] initWithFrame:CGRectZero];
    _underline.translatesAutoresizingMaskIntoConstraints = NO;
    _underline.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.18];

    [self addSubview:_textView];
    [self addSubview:_placeholderLabel];
    [self addSubview:_clearButton];
    [self addSubview:_underline];

    [NSLayoutConstraint activateConstraints:@[
        [_textView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [_textView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_textView.trailingAnchor constraintEqualToAnchor:_clearButton.leadingAnchor constant:-8.0],
        [_textView.bottomAnchor constraintEqualToAnchor:_underline.topAnchor constant:-2.0],
        [_placeholderLabel.leadingAnchor constraintEqualToAnchor:_textView.leadingAnchor],
        [_placeholderLabel.centerYAnchor constraintEqualToAnchor:_textView.centerYAnchor],
        [_placeholderLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_clearButton.leadingAnchor constant:-8.0],
        [_clearButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_clearButton.centerYAnchor constraintEqualToAnchor:_textView.centerYAnchor],
        [_clearButton.widthAnchor constraintEqualToConstant:24.0],
        [_clearButton.heightAnchor constraintEqualToConstant:24.0],
        [_underline.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_underline.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_underline.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [_underline.heightAnchor constraintEqualToConstant:1.0],
    ]];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textDidChange:)
                                                 name:UITextViewTextDidChangeNotification
                                               object:_textView];
    [self updatePlaceholderVisibility];
}

- (CGSize)intrinsicContentSize
{
    CGSize textSize = [_textView sizeThatFits:CGSizeMake(CGRectGetWidth(self.bounds), CGFLOAT_MAX)];
    return CGSizeMake(UIViewNoIntrinsicMetric, MAX(48.0, textSize.height + 3.0));
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self invalidateIntrinsicContentSize];
}

- (NSString *)text
{
    return _textView.text;
}

- (void)setText:(NSString *)text
{
    _textView.text = text;
    [self textDidChange:nil];
}

- (void)setPlaceholder:(NSString *)placeholder
{
    _placeholder = [placeholder copy];
    _placeholderLabel.text = placeholder;
    [self updatePlaceholderVisibility];
}

- (void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    _textView.textColor = textColor;
}

- (void)setFont:(UIFont *)font
{
    _font = font;
    _textView.font = font;
    _placeholderLabel.font = font;
}

- (void)setAdjustsFontForContentSizeCategory:(BOOL)adjustsFontForContentSizeCategory
{
    _adjustsFontForContentSizeCategory = adjustsFontForContentSizeCategory;
    _textView.adjustsFontForContentSizeCategory = adjustsFontForContentSizeCategory;
    _placeholderLabel.adjustsFontForContentSizeCategory = adjustsFontForContentSizeCategory;
}

- (void)setHidesPlaceholderOnInput:(BOOL)hidesPlaceholderOnInput
{
    _hidesPlaceholderOnInput = hidesPlaceholderOnInput;
    [self updatePlaceholderVisibility];
}

- (void)clearButtonPressed:(id)sender
{
    self.text = @"";
    if ([_textView.delegate respondsToSelector:@selector(textViewDidChange:)])
        [_textView.delegate textViewDidChange:_textView];
}

- (void)textDidChange:(NSNotification *)notification
{
    [self updatePlaceholderVisibility];
    [self invalidateIntrinsicContentSize];
}

- (void)textViewContentSizeDidChange:(CGSize)size
{
    [_textView invalidateIntrinsicContentSize];
    [self invalidateIntrinsicContentSize];
    if ([_layoutDelegate respondsToSelector:@selector(multilineTextField:didChangeContentSize:)])
        [_layoutDelegate multilineTextField:self didChangeContentSize:size];
}

- (void)updatePlaceholderVisibility
{
    BOOL hasText = _textView.text.length > 0;
    _placeholderLabel.hidden = _placeholder.length == 0 || (_hidesPlaceholderOnInput && hasText);
    _clearButton.hidden = !hasText;
}

@end

@implementation MDCTextInputControllerUnderline

- (instancetype)initWithTextInput:(MDCMultilineTextField *)textInput
{
    self = [super init];
    if (self)
        _textInput = textInput;
    return self;
}

- (void)setInlinePlaceholderFont:(UIFont *)inlinePlaceholderFont
{
    _inlinePlaceholderFont = inlinePlaceholderFont;
    _textInput.font = inlinePlaceholderFont;
}

- (void)setInlinePlaceholderColor:(UIColor *)inlinePlaceholderColor
{
    _inlinePlaceholderColor = inlinePlaceholderColor;
    [_textInput setValue:inlinePlaceholderColor forKeyPath:@"placeholderLabel.textColor"];
}

- (void)setFloatingPlaceholderNormalColor:(UIColor *)floatingPlaceholderNormalColor
{
    _floatingPlaceholderNormalColor = floatingPlaceholderNormalColor;
}

@end
