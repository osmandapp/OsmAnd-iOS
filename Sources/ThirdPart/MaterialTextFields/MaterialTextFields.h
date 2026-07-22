#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MDCTextInputTextInsetsMode) {
    MDCTextInputTextInsetsModeNever = 0,
    MDCTextInputTextInsetsModeIfContent,
    MDCTextInputTextInsetsModeAlways,
};

@protocol MDCMultilineTextInput <NSObject>
@property(nonatomic, assign) MDCTextInputTextInsetsMode textInsetsMode;
@property(nonatomic, assign) BOOL hidesPlaceholderOnInput;
@end

@protocol MDCMultilineTextInputLayoutDelegate <NSObject>
- (void)multilineTextField:(id<MDCMultilineTextInput> _Nonnull)multilineTextField
      didChangeContentSize:(CGSize)size;
@end

@interface MDCMultilineTextField : UIView <MDCMultilineTextInput>

@property(nonatomic, strong, readonly) UITextView *textView;
@property(nonatomic, strong, readonly) UIButton *clearButton;
@property(nonatomic, strong, readonly) UIView *underline;
@property(nonatomic, weak, nullable) IBOutlet id<MDCMultilineTextInputLayoutDelegate> layoutDelegate;
@property(nonatomic, copy, nullable) NSString *text;
@property(nonatomic, copy, nullable) NSString *placeholder;
@property(nonatomic, strong, nullable) UIColor *textColor;
@property(nonatomic, strong, nullable) UIFont *font;
@property(nonatomic, assign) BOOL adjustsFontForContentSizeCategory;
@property(nonatomic, assign) MDCTextInputTextInsetsMode textInsetsMode;
@property(nonatomic, assign) BOOL hidesPlaceholderOnInput;

@end

@interface MDCTextInputControllerUnderline : NSObject

@property(nonatomic, weak, readonly, nullable) MDCMultilineTextField *textInput;
@property(nonatomic, strong, nullable) UIFont *inlinePlaceholderFont;
@property(nonatomic, strong, nullable) UIColor *inlinePlaceholderColor;
@property(nonatomic, strong, nullable) UIColor *floatingPlaceholderActiveColor;
@property(nonatomic, strong, nullable) UIColor *floatingPlaceholderNormalColor;

- (instancetype)initWithTextInput:(MDCMultilineTextField *)textInput;
- (void)setFloatingPlaceholderNormalColor:(nullable UIColor *)floatingPlaceholderNormalColor;

@end

NS_ASSUME_NONNULL_END
