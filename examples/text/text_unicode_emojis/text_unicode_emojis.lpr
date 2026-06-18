program text_unicode_emojis;

{$mode objfpc}{$H+}

uses
  cmem, raylib, sysutils, math;

const
  screenWidth = 800;
  screenHeight = 450;
  EMOJI_PER_WIDTH = 8;
  EMOJI_PER_HEIGHT = 4;

type
  TEmojiData = record
    index: integer;
    message: integer;
    color: TColorB;
  end;

  TMessageData = record
    text: PChar;
    language: PChar;
  end;

var
  emoji: array[0..EMOJI_PER_WIDTH * EMOJI_PER_HEIGHT - 1] of TEmojiData;
  hovered, selected: integer;
  fontDefault, fontAsian, fontEmoji: TFont;
  emojiCodepoints: PChar;

const
  // String containing 180 emoji codepoints separated by a #0 char
  emojiCodepointsConst: PChar =
    #$F0#$9F#$8C#$80 + #0 +
    #$F0#$9F#$98#$80 + #0 +
    #$F0#$9F#$98#$82 + #0 +
    #$F0#$9F#$A4#$A3 + #0 +
    #$F0#$9F#$98#$83 + #0 +
    #$F0#$9F#$98#$86 + #0 +
    #$F0#$9F#$98#$89 + #0 +
    #$F0#$9F#$98#$8B + #0 +
    #$F0#$9F#$98#$8E + #0 +
    #$F0#$9F#$98#$8D + #0 +
    #$F0#$9F#$98#$98 + #0 +
    #$F0#$9F#$98#$97 + #0 +
    #$F0#$9F#$98#$99 + #0 +
    #$F0#$9F#$98#$9A + #0 +
    #$F0#$9F#$99#$82 + #0 +
    #$F0#$9F#$A4#$97 + #0 +
    #$F0#$9F#$A4#$A9 + #0 +
    #$F0#$9F#$A4#$94 + #0 +
    #$F0#$9F#$A4#$A8 + #0 +
    #$F0#$9F#$98#$90 + #0 +
    #$F0#$9F#$98#$91 + #0 +
    #$F0#$9F#$98#$B6 + #0 +
    #$F0#$9F#$99#$84 + #0 +
    #$F0#$9F#$98#$8F + #0 +
    #$F0#$9F#$98#$A3 + #0 +
    #$F0#$9F#$98#$A5 + #0 +
    #$F0#$9F#$98#$AE + #0 +
    #$F0#$9F#$A4#$90 + #0 +
    #$F0#$9F#$98#$AF + #0 +
    #$F0#$9F#$98#$AA + #0 +
    #$F0#$9F#$98#$AB + #0 +
    #$F0#$9F#$98#$B4 + #0 +
    #$F0#$9F#$98#$8C + #0 +
    #$F0#$9F#$98#$9B + #0 +
    #$F0#$9F#$98#$9D + #0 +
    #$F0#$9F#$A4#$A4 + #0 +
    #$F0#$9F#$98#$92 + #0 +
    #$F0#$9F#$98#$95 + #0 +
    #$F0#$9F#$99#$83 + #0 +
    #$F0#$9F#$A4#$91 + #0 +
    #$F0#$9F#$98#$B2 + #0 +
    #$F0#$9F#$99#$81 + #0 +
    #$F0#$9F#$98#$96 + #0 +
    #$F0#$9F#$98#$9E + #0 +
    #$F0#$9F#$98#$9F + #0 +
    #$F0#$9F#$98#$A4 + #0 +
    #$F0#$9F#$98#$A2 + #0 +
    #$F0#$9F#$98#$AD + #0 +
    #$F0#$9F#$98#$A6 + #0 +
    #$F0#$9F#$98#$A9 + #0 +
    #$F0#$9F#$A4#$AF + #0 +
    #$F0#$9F#$98#$AC + #0 +
    #$F0#$9F#$98#$B0 + #0 +
    #$F0#$9F#$98#$B1 + #0 +
    #$F0#$9F#$98#$B3 + #0 +
    #$F0#$9F#$A4#$AA + #0 +
    #$F0#$9F#$98#$B5 + #0 +
    #$F0#$9F#$98#$A1 + #0 +
    #$F0#$9F#$98#$A0 + #0 +
    #$F0#$9F#$A4#$AC + #0 +
    #$F0#$9F#$98#$B7 + #0 +
    #$F0#$9F#$A4#$92 + #0 +
    #$F0#$9F#$A4#$95 + #0 +
    #$F0#$9F#$A4#$A2 + #0 +
    #$F0#$9F#$A4#$AE + #0 +
    #$F0#$9F#$A4#$A7 + #0 +
    #$F0#$9F#$98#$87 + #0 +
    #$F0#$9F#$A4#$A0 + #0 +
    #$F0#$9F#$A4#$AB + #0 +
    #$F0#$9F#$A4#$AD + #0 +
    #$F0#$9F#$A7#$90 + #0 +
    #$F0#$9F#$A4#$93 + #0 +
    #$F0#$9F#$98#$88 + #0 +
    #$F0#$9F#$91#$BF + #0 +
    #$F0#$9F#$91#$B9 + #0 +
    #$F0#$9F#$91#$BA + #0 +
    #$F0#$9F#$92#$80 + #0 +
    #$F0#$9F#$91#$BB + #0 +
    #$F0#$9F#$91#$BD + #0 +
    #$F0#$9F#$91#$BE + #0 +
    #$F0#$9F#$A4#$96 + #0 +
    #$F0#$9F#$92#$A9 + #0 +
    #$F0#$9F#$98#$BA + #0 +
    #$F0#$9F#$98#$B8 + #0 +
    #$F0#$9F#$98#$B9 + #0 +
    #$F0#$9F#$98#$BB + #0 +
    #$F0#$9F#$98#$BD + #0 +
    #$F0#$9F#$99#$80 + #0 +
    #$F0#$9F#$98#$BF + #0 +
    #$F0#$9F#$8C#$BE + #0 +
    #$F0#$9F#$8C#$BF + #0 +
    #$F0#$9F#$8D#$80 + #0 +
    #$F0#$9F#$8D#$83 + #0 +
    #$F0#$9F#$8D#$87 + #0 +
    #$F0#$9F#$8D#$93 + #0 +
    #$F0#$9F#$A5#$9D + #0 +
    #$F0#$9F#$8D#$85 + #0 +
    #$F0#$9F#$A5#$A5 + #0 +
    #$F0#$9F#$A5#$91 + #0 +
    #$F0#$9F#$8D#$86 + #0 +
    #$F0#$9F#$A5#$94 + #0 +
    #$F0#$9F#$A5#$95 + #0 +
    #$F0#$9F#$8C#$BD + #0 +
    #$F0#$9F#$8C#$B6 + #0 +
    #$F0#$9F#$A5#$92 + #0 +
    #$F0#$9F#$A5#$A6 + #0 +
    #$F0#$9F#$8D#$84 + #0 +
    #$F0#$9F#$A5#$9C + #0 +
    #$F0#$9F#$8C#$B0 + #0 +
    #$F0#$9F#$8D#$9E + #0 +
    #$F0#$9F#$A5#$90 + #0 +
    #$F0#$9F#$A5#$96 + #0 +
    #$F0#$9F#$A5#$A8 + #0 +
    #$F0#$9F#$A5#$9E + #0 +
    #$F0#$9F#$A7#$80 + #0 +
    #$F0#$9F#$8D#$96 + #0 +
    #$F0#$9F#$8D#$97 + #0 +
    #$F0#$9F#$A5#$A9 + #0 +
    #$F0#$9F#$A5#$93 + #0 +
    #$F0#$9F#$8D#$94 + #0 +
    #$F0#$9F#$8D#$9F + #0 +
    #$F0#$9F#$8D#$95 + #0 +
    #$F0#$9F#$8C#$AD + #0 +
    #$F0#$9F#$A5#$AA + #0 +
    #$F0#$9F#$8C#$AE + #0 +
    #$F0#$9F#$8C#$AF + #0 +
    #$F0#$9F#$A5#$99 + #0 +
    #$F0#$9F#$A5#$9A + #0 +
    #$F0#$9F#$8D#$B3 + #0 +
    #$F0#$9F#$A5#$98 + #0 +
    #$F0#$9F#$8D#$B2 + #0 +
    #$F0#$9F#$A5#$A3 + #0 +
    #$F0#$9F#$A5#$97 + #0 +
    #$F0#$9F#$8D#$BF + #0 +
    #$F0#$9F#$A5#$AB + #0 +
    #$F0#$9F#$8D#$B1 + #0 +
    #$F0#$9F#$8D#$98 + #0 +
    #$F0#$9F#$8D#$9D + #0 +
    #$F0#$9F#$8D#$A0 + #0 +
    #$F0#$9F#$8D#$A2 + #0 +
    #$F0#$9F#$8D#$A5 + #0 +
    #$F0#$9F#$8D#$A1 + #0 +
    #$F0#$9F#$A5#$9F + #0 +
    #$F0#$9F#$A5#$A1 + #0 +
    #$F0#$9F#$8D#$A6 + #0 +
    #$F0#$9F#$8D#$AA + #0 +
    #$F0#$9F#$8E#$82 + #0 +
    #$F0#$9F#$8D#$B0 + #0 +
    #$F0#$9F#$A5#$A7 + #0 +
    #$F0#$9F#$8D#$AB + #0 +
    #$F0#$9F#$8D#$AF + #0 +
    #$F0#$9F#$8D#$BC + #0 +
    #$F0#$9F#$A5#$9B + #0 +
    #$F0#$9F#$8D#$B5 + #0 +
    #$F0#$9F#$8D#$B6 + #0 +
    #$F0#$9F#$8D#$BE + #0 +
    #$F0#$9F#$8D#$B7 + #0 +
    #$F0#$9F#$8D#$BB + #0 +
    #$F0#$9F#$A5#$82 + #0 +
    #$F0#$9F#$A5#$83 + #0 +
    #$F0#$9F#$A5#$A4 + #0 +
    #$F0#$9F#$A5#$A2 + #0 +
    #$F0#$9F#$91#$81 + #0 +
    #$F0#$9F#$91#$85 + #0 +
    #$F0#$9F#$91#$84 + #0 +
    #$F0#$9F#$92#$8B + #0 +
    #$F0#$9F#$92#$98 + #0 +
    #$F0#$9F#$92#$93 + #0 +
    #$F0#$9F#$92#$97 + #0 +
    #$F0#$9F#$92#$99 + #0 +
    #$F0#$9F#$92#$9B + #0 +
    #$F0#$9F#$A7#$A1 + #0 +
    #$F0#$9F#$92#$9C + #0 +
    #$F0#$9F#$96#$A4 + #0 +
    #$F0#$9F#$92#$9D + #0 +
    #$F0#$9F#$92#$9F + #0 +
    #$F0#$9F#$92#$8C + #0 +
    #$F0#$9F#$92#$A4 + #0 +
    #$F0#$9F#$92#$A2 + #0 +
    #$F0#$9F#$92#$A3 + #0;

// Messages array
const
  messages: array[0..46] of TMessageData = (
    (text: #$46#$61#$6C#$73#$63#$68#$65#$73#$20#$C3#$9C#$62#$65#$6E#$20#$76#$6F#$6E#$20#$58#$79#$6C#$6F#$70#$68#$6F#$6E#$6D#$75#$73#$69#$6B#$20#$71#$75#$C3#$A4#$6C#$74#$20#$6A#$65#$64#$65#$6E#$20#$67#$72#$C3#$B6#$C3#$9F#$65#$72#$65#$6E#$20#$5A#$77#$65#$72#$67; language: 'German'),
    (text: #$42#$65#$69#$C3#$9F#$20#$6E#$69#$63#$68#$74#$20#$69#$6E#$20#$64#$69#$65#$20#$48#$61#$6E#$64#$2C#$20#$64#$69#$65#$20#$64#$69#$63#$68#$20#$66#$C3#$BC#$74#$74#$65#$72#$74#$2E; language: 'German'),
    (text: #$41#$75#$C3#$9F#$65#$72#$6F#$72#$64#$65#$6E#$74#$6C#$69#$63#$68#$65#$20#$C3#$9C#$62#$65#$6C#$20#$65#$72#$66#$6F#$72#$64#$65#$72#$6E#$20#$61#$75#$C3#$9F#$65#$72#$6F#$72#$64#$65#$6E#$74#$6C#$69#$63#$68#$65#$20#$4D#$69#$74#$74#$65#$6C#$2E; language: 'German'),
    (text: #$D4#$BF#$D6#$80#$D5#$B6#$D5#$A1#$D5#$B4#$20#$D5#$A1#$D5#$BA#$D5#$A1#$D5#$AF#$D5#$AB#$20#$D5#$B8#$D6#$82#$D5#$A5#$D5#$AC#$20#$D6#$87#$20#$D5#$AB#$D5#$B6#$D5#$AE#$D5#$AB#$20#$D5#$A1#$D5#$B6#$D5#$B0#$D5#$A1#$D5#$B6#$D5#$A3#$D5#$AB#$D5#$BD#$D5#$BF#$20#$D5#$B9#$D5#$A8#$D5#$B6#$D5#$A5#$D6#$80; language: 'Armenian'),
    (text: #$D4#$B5#$D6#$80#$D5#$A2#$20#$D5#$B8#$D6#$80#$20#$D5#$AF#$D5#$A1#$D6#$81#$D5#$AB#$D5#$B6#$D5#$A8#$20#$D5#$A5#$D5#$AF#$D5#$A1#$D6#$82#$20#$D5#$A1#$D5#$B6#$D5#$BF#$D5#$A1#$D5#$BC#$2C#$20#$D5#$AE#$D5#$A1#$D5#$BC#$D5#$A5#$D6#$80#$D5#$A8#$20#$D5#$A1#$D5#$BD#$D5#$A1#$D6#$81#$D5#$AB#$D5#$B6#$2E#$2E#$2E#$20#$C2#$AB#$D4#$BF#$D5#$B8#$D5#$BF#$D5#$A8#$20#$D5#$B4#$D5#$A5#$D6#$80#$D5#$B8#$D5#$B6#$D6#$81#$D5#$AB#$D6#$81#$20#$D5#$A7#$3A#$C2#$BB; language: 'Armenian'),
    (text: #$D4#$B3#$D5#$A1#$D5#$BC#$D5#$A8#$D5#$9D#$20#$D5#$A3#$D5#$A1#$D6#$80#$D5#$B6#$D5#$A1#$D5#$B6#$2C#$20#$D5#$B1#$D5#$AB#$D6#$82#$D5#$B6#$D5#$A8#$D5#$9D#$20#$D5#$B1#$D5#$B4#$D5#$BC#$D5#$A1#$D5#$B6; language: 'Armenian'),
    (text: #$4A#$65#$C5#$BC#$75#$20#$6B#$6C#$C4#$85#$74#$77#$2C#$20#$73#$70#$C5#$82#$C3#$B3#$64#$C5#$BA#$20#$46#$69#$6E#$6F#$6D#$20#$63#$7A#$C4#$99#$C5#$9B#$C4#$87#$20#$67#$72#$79#$20#$68#$61#$C5#$84#$62#$21; language: 'Polish'),
    (text: #$44#$6F#$62#$72#$79#$6D#$69#$20#$63#$68#$C4#$99#$63#$69#$61#$6D#$69#$20#$6A#$65#$73#$74#$20#$70#$69#$65#$6B#$C5#$82#$6F#$20#$77#$79#$62#$72#$75#$6B#$6F#$77#$61#$6E#$65#$2E; language: 'Polish'),
    (text: #$C3#$8E#$C8#$9B#$69#$20#$6D#$75#$6C#$C8#$9B#$75#$6D#$65#$73#$63#$20#$63#$C4#$83#$20#$61#$69#$20#$61#$6C#$65#$73#$20#$72#$61#$79#$6C#$69#$62#$2E#$0A#$C8#$98#$69#$20#$73#$70#$65#$72#$20#$73#$C4#$83#$20#$61#$69#$20#$6F#$20#$7A#$69#$20#$62#$75#$6E#$C4#$83#$21; language: 'Romanian'),
    (text: #$D0#$AD#$D1#$85#$2C#$20#$D1#$87#$D1#$83#$D0#$B6#$D0#$B0#$D0#$BA#$2C#$20#$D0#$BE#$D0#$B1#$D1#$89#$D0#$B8#$D0#$B9#$20#$D1#$81#$D1#$8A#$D1#$91#$D0#$BC#$20#$D1#$86#$D0#$B5#$D0#$BD#$20#$D1#$88#$D0#$BB#$D1#$8F#$D0#$BF#$20#$28#$D1#$8E#$D1#$84#$D1#$82#$D1#$8C#$29#$20#$D0#$B2#$D0#$B4#$D1#$80#$D1#$8B#$D0#$B7#$D0#$B3#$21; language: 'Russian'),
    (text: #$D0#$AF#$20#$D0#$BB#$D1#$8E#$D0#$B1#$D0#$BB#$D1#$8E#$20#$72#$61#$79#$6C#$69#$62#$21; language: 'Russian'),
    (text: #$D0#$9C#$D0#$BE#$D0#$BB#$D1#$87#$D0#$B8#$2C#$20#$D1#$81#$D0#$BA#$D1#$80#$D1#$8B#$D0#$B2#$D0#$B0#$D0#$B9#$D1#$81#$D1#$8F#$20#$D0#$B8#$20#$D1#$82#$D0#$B0#$D0#$B8#$0A#$D0#$98#$20#$D1#$87#$D1#$83#$D0#$B2#$D1#$81#$D1#$82#$D0#$B2#$D0#$B0#$20#$D0#$B8#$20#$D0#$BC#$D0#$B5#$D1#$87#$D1#$82#$D1#$8B#$20#$D1#$81#$D0#$B2#$D0#$BE#$D0#$B8#$20#$E2#$80#$93#$0A#$D0#$9F#$D1#$83#$D1#$81#$D0#$BA#$D0#$B0#$D0#$B9#$20#$D0#$B2#$20#$D0#$B4#$D1#$83#$D1#$88#$D0#$B5#$D0#$B2#$D0#$BD#$D0#$BE#$D0#$B9#$20#$D0#$B3#$D0#$BB#$D1#$83#$D0#$B1#$D0#$B8#$D0#$BD#$D0#$B5#$0A#$D0#$98#$20#$D0#$B2#$D1#$81#$D1#$85#$D0#$BE#$D0#$B4#$D1#$8F#$D1#$82#$20#$D0#$B8#$20#$D0#$B7#$D0#$B0#$D0#$B9#$D0#$B4#$D1#$83#$D1#$82#$20#$D0#$BE#$D0#$BD#$D0#$B5#$0A#$D0#$9A#$D0#$B0#$D0#$BA#$20#$D0#$B7#$D0#$B2#$D0#$B5#$D0#$B7#$D0#$B4#$D1#$8B#$20#$D1#$8F#$D1#$81#$D0#$BD#$D1#$8B#$D0#$B5#$20#$D0#$B2#$20#$D0#$BD#$D0#$BE#$D1#$87#$D0#$B8#$2D#$0A#$D0#$9B#$D1#$8E#$D0#$B1#$D1#$83#$D0#$B9#$D1#$81#$D1#$8F#$20#$D0#$B8#$D0#$BC#$D0#$B8#$20#$E2#$80#$93#$20#$D0#$B8#$20#$D0#$BC#$D0#$BE#$D0#$BB#$D1#$87#$D0#$B8#$2E; language: 'Russian'),
    (text: #$56#$6F#$69#$78#$20#$61#$6D#$62#$69#$67#$75#$C3#$AB#$20#$64#$E2#$80#$99#$75#$6E#$20#$63#$C5#$93#$75#$72#$20#$71#$75#$69#$20#$61#$75#$20#$7A#$C3#$A9#$70#$68#$79#$72#$20#$70#$72#$C3#$A9#$66#$C3#$A8#$72#$65#$20#$6C#$65#$73#$20#$6A#$61#$74#$74#$65#$73#$20#$64#$65#$20#$6B#$69#$77#$69; language: 'French'),
    (text: #$42#$65#$6E#$6A#$61#$6D#$C3#$AD#$6E#$20#$70#$69#$64#$69#$C3#$B3#$20#$75#$6E#$61#$20#$62#$65#$62#$69#$64#$61#$20#$64#$65#$20#$6B#$69#$77#$69#$20#$79#$20#$66#$72#$65#$73#$61#$3B#$20#$4E#$6F#$C3#$A9#$2C#$20#$73#$69#$6E#$20#$76#$65#$72#$67#$C3#$BC#$65#$6E#$7A#$61#$2C#$20#$6C#$61#$20#$6D#$C3#$A1#$73#$20#$65#$78#$71#$75#$69#$73#$69#$74#$61#$20#$63#$68#$61#$6D#$70#$61#$C3#$B1#$61#$20#$64#$65#$6C#$20#$6D#$65#$6E#$C3#$BA#$2E; language: 'Spanish'),
    (text: #$CE#$A4#$CE#$B1#$CF#$87#$CE#$AF#$CF#$83#$CF#$84#$CE#$B7#$20#$CE#$B1#$CE#$BB#$CF#$8E#$CF#$80#$CE#$B7#$CE#$BE#$20#$CE#$B2#$CE#$B1#$CF#$86#$CE#$AE#$CF#$82#$20#$CF#$88#$CE#$B7#$CE#$BC#$CE#$AD#$CE#$BD#$CE#$B7#$20#$CE#$B3#$CE#$B7#$2C#$20#$CE#$B4#$CF#$81#$CE#$B1#$CF#$83#$CE#$BA#$CE#$B5#$CE#$BB#$CE#$AF#$CE#$B6#$CE#$B5#$CE#$B9#$20#$CF#$85#$CF#$80#$CE#$AD#$CF#$81#$20#$CE#$BD#$CF#$89#$CE#$B8#$CF#$81#$CE#$BF#$CF#$8D#$20#$CE#$BA#$CF#$85#$CE#$BD#$CF#$8C#$CF#$82; language: 'Greek'),
    (text: #$CE#$97#$20#$CE#$BA#$CE#$B1#$CE#$BB#$CF#$8D#$CF#$84#$CE#$B5#$CF#$81#$CE#$B7#$20#$CE#$AC#$CE#$BC#$CF#$85#$CE#$BD#$CE#$B1#$20#$CE#$B5#$CE#$AF#$CE#$BD#$CE#$B1#$CE#$B9#$20#$CE#$B7#$20#$CE#$B5#$CF#$80#$CE#$AF#$CE#$B8#$CE#$B5#$CF#$83#$CE#$B7#$2E; language: 'Greek'),
    (text: #$CE#$A7#$CF#$81#$CF#$8C#$CE#$BD#$CE#$B9#$CE#$B1#$20#$CE#$BA#$CE#$B1#$CE#$B9#$20#$CE#$B6#$CE#$B1#$CE#$BC#$CE#$AC#$CE#$BD#$CE#$B9#$CE#$B1#$21; language: 'Greek'),
    (text: #$CE#$A0#$CF#$8E#$CF#$82#$20#$CF#$84#$CE#$B1#$20#$CF#$80#$CE#$B1#$CF#$82#$20#$CF#$83#$CE#$AE#$CE#$BC#$CE#$B5#$CF#$81#$CE#$B1#$3B; language: 'Greek'),
    (text: #$E6#$88#$91#$E8#$83#$BD#$E5#$90#$9E#$E4#$B8#$8B#$E7#$8E#$BB#$E7#$92#$83#$E8#$80#$8C#$E4#$B8#$8D#$E4#$BC#$A4#$E8#$BA#$AB#$E4#$BD#$93#$E3#$80#$82; language: 'Chinese'),
    (text: #$E4#$BD#$A0#$E5#$90#$83#$E4#$BA#$86#$E5#$90#$97#$EF#$BC#$9F; language: 'Chinese'),
    (text: #$E4#$B8#$8D#$E4#$BD#$9C#$E4#$B8#$8D#$E6#$AD#$BB#$E3#$80#$82; language: 'Chinese'),
    (text: #$E6#$9C#$80#$E8#$BF#$91#$E5#$A5#$BD#$E5#$90#$97#$EF#$BC#$9F; language: 'Chinese'),
    (text: #$E5#$A1#$9E#$E7#$BF#$81#$E5#$A4#$B1#$E9#$A9#$AC#$EF#$BC#$8C#$E7#$84#$89#$E7#$9F#$A5#$E9#$9D#$9E#$E7#$A6#$8F#$E3#$80#$82; language: 'Chinese'),
    (text: #$E5#$8D#$83#$E5#$86#$9B#$E6#$98#$93#$E5#$BE#$97#$2C#$20#$E4#$B8#$80#$E5#$B0#$86#$E9#$9A#$BE#$E6#$B1#$82; language: 'Chinese'),
    (text: #$E4#$B8#$87#$E4#$BA#$8B#$E5#$BC#$80#$E5#$A4#$B4#$E9#$9A#$BE#$E3#$80#$82; language: 'Chinese'),
    (text: #$E9#$A3#$8E#$E6#$97#$A0#$E5#$B8#$B8#$E9#$A1#$BA#$EF#$BC#$8C#$E5#$85#$B5#$E6#$97#$A0#$E5#$B8#$B8#$E8#$83#$9C#$E3#$80#$82; language: 'Chinese'),
    (text: #$E6#$B4#$BB#$E5#$88#$B0#$E8#$80#$81#$EF#$BC#$8C#$E5#$AD#$A6#$E5#$88#$B0#$E8#$80#$81#$E3#$80#$82; language: 'Chinese'),
    (text: #$E4#$B8#$80#$E8#$A8#$80#$E6#$97#$A2#$E5#$87#$BA#$EF#$BC#$8C#$E9#$A9#$B7#$E9#$A9#$AC#$E9#$9A#$BE#$E8#$BF#$BD#$E3#$80#$82; language: 'Chinese'),
    (text: #$E8#$B7#$AF#$E9#$81#$A5#$E7#$9F#$A5#$E9#$A9#$AC#$E5#$8A#$9B#$EF#$BC#$8C#$E6#$97#$A5#$E4#$B9#$85#$E8#$A7#$81#$E4#$BA#$BA#$E5#$BF#$83; language: 'Chinese'),
    (text: #$E6#$9C#$89#$E7#$90#$86#$E8#$B5#$B0#$E9#$81#$8D#$E5#$A4#$A9#$E4#$B8#$8B#$EF#$BC#$8C#$E6#$97#$A0#$E7#$90#$86#$E5#$AF#$B8#$E6#$AD#$A5#$E9#$9A#$BE#$E8#$A1#$8C#$E3#$80#$82; language: 'Chinese'),
    (text: #$E7#$8C#$BF#$E3#$82#$82#$E6#$9C#$A8#$E3#$81#$8B#$E3#$82#$89#$E8#$90#$BD#$E3#$81#$A1#$E3#$82#$8B; language: 'Japanese'),
    (text: #$E4#$BA#$80#$E3#$81#$AE#$E7#$94#$B2#$E3#$82#$88#$E3#$82#$8A#$E5#$B9#$B4#$E3#$81#$AE#$E5#$8A#$9F; language: 'Japanese'),
    (text: #$E3#$81#$86#$E3#$82#$89#$E3#$82#$84#$E3#$81#$BE#$E3#$81#$97#$20#$20#$E6#$80#$9D#$E3#$81#$B2#$E5#$88#$87#$E3#$82#$8B#$E6#$99#$82#$20#$20#$E7#$8C#$AB#$E3#$81#$AE#$E6#$81#$8B; language: 'Japanese'),
    (text: #$E8#$99#$8E#$E7#$A9#$B4#$E3#$81#$AB#$E5#$85#$A5#$E3#$82#$89#$E3#$81#$9A#$E3#$82#$93#$E3#$81#$B0#$E8#$99#$8E#$E5#$AD#$90#$E3#$82#$92#$E5#$BE#$97#$E3#$81#$9A#$E3#$80#$82; language: 'Japanese'),
    (text: #$E4#$BA#$8C#$E5#$85#$8E#$E3#$82#$92#$E8#$BF#$BD#$E3#$81#$86#$E8#$80#$85#$E3#$81#$AF#$E4#$B8#$80#$E5#$85#$8E#$E3#$82#$92#$E3#$82#$82#$E5#$BE#$97#$E3#$81#$9A#$E3#$80#$82; language: 'Japanese'),
    (text: #$E9#$A6#$AC#$E9#$B9#$BF#$E3#$81#$AF#$E6#$AD#$BB#$E3#$81#$AA#$E3#$81#$AA#$E3#$81#$8D#$E3#$82#$83#$E6#$B2#$BB#$E3#$82#$89#$E3#$81#$AA#$E3#$81#$84#$E3#$80#$82; language: 'Japanese'),
    (text: #$E6#$9E#$AF#$E9#$87#$8E#$E8#$B7#$AF#$E3#$81#$AB#$E3#$80#$80#$E5#$BD#$B1#$E3#$81#$8B#$E3#$81#$95#$E3#$81#$AA#$E3#$82#$8A#$E3#$81#$A6#$E3#$80#$80#$E3#$82#$8F#$E3#$81#$8B#$E3#$82#$8C#$E3#$81#$91#$E3#$82#$8A; language: 'Japanese'),
    (text: #$E7#$B9#$B0#$E3#$82#$8A#$E8#$BF#$94#$E3#$81#$97#$E9#$BA#$A6#$E3#$81#$AE#$E7#$95#$9D#$E7#$B8#$AB#$E3#$81#$B5#$E8#$83#$A1#$E8#$9D#$B6#$E5#$93#$89; language: 'Japanese'),
    (text: #$EC#$95#$84#$EB#$93#$9D#$ED#$95#$9C#$20#$EB#$B0#$94#$EB#$8B#$A4#$20#$EC#$9C#$84#$EC#$97#$90#$20#$EA#$B0#$88#$EB#$A7#$A4#$EA#$B8#$B0#$20#$EB#$91#$90#$EC#$97#$87#$20#$EB#$82#$A0#$EC#$95#$84#$20#$EB#$8F#$88#$EB#$8B#$A4#$2E#$0A#$EB#$84#$88#$ED#$9B#$8C#$EB#$84#$88#$ED#$9B#$8C#$20#$EC#$8B#$9C#$EB#$A5#$BC#$20#$EC#$93#$B4#$EB#$8B#$A4#$2E#$20#$EB#$AA#$A8#$EB#$A5#$B4#$EB#$8A#$94#$20#$EB#$82#$98#$EB#$9D#$BC#$20#$EA#$B8#$80#$EC#$9E#$90#$EB#$8B#$A4#$2E#$0A#$EB#$84#$90#$EB#$94#$B0#$EB#$9E#$80#$20#$ED#$95#$98#$EB#$8A#$98#$20#$EB#$B3#$B5#$ED#$8C#$90#$EC#$97#$90#$20#$EB#$82#$98#$EB#$8F#$84#$20#$EA#$B0#$99#$EC#$9D#$B4#$20#$EC#$8B#$9C#$EB#$A5#$BC#$20#$EC#$93#$B4#$EB#$8B#$A4#$2E; language: 'Korean'),
    (text: #$EC#$A0#$9C#$20#$EB#$88#$88#$EC#$97#$90#$20#$EC#$95#$88#$EA#$B2#$BD#$EC#$9D#$B4#$EB#$8B#$A4; language: 'Korean'),
    (text: #$EA#$BF#$A9#$20#$EB#$A8#$B9#$EA#$B3#$A0#$20#$EC#$95#$8C#$20#$EB#$A8#$B9#$EB#$8A#$94#$EB#$8B#$A4; language: 'Korean'),
    (text: #$EB#$A1#$9C#$EB#$A7#$88#$EB#$8A#$94#$20#$ED#$95#$98#$EB#$A3#$A8#$EC#$95#$84#$EC#$B9#$A8#$EC#$97#$90#$20#$EC#$9D#$B4#$EB#$A3#$A8#$EC#$96#$B4#$EC#$A7#$84#$20#$EA#$B2#$83#$EC#$9D#$B4#$20#$EC#$95#$84#$EB#$8B#$88#$EB#$8B#$A4; language: 'Korean'),
    (text: #$EA#$B3#$A0#$EC#$83#$9D#$20#$EB#$81#$9D#$EC#$97#$90#$20#$EB#$82#$99#$EC#$9D#$B4#$20#$EC#$98#$A8#$EB#$8B#$A4; language: 'Korean'),
    (text: #$EA#$B0#$9C#$EC#$B2#$9C#$EC#$97#$90#$EC#$84#$9C#$20#$EC#$9A#$A9#$20#$EB#$82#$9C#$EB#$8B#$A4; language: 'Korean'),
    (text: #$EC#$95#$88#$EB#$85#$95#$ED#$95#$98#$EC#$84#$B8#$EC#$9A#$94#$3F; language: 'Korean'),
    (text: #$EB#$A7#$8C#$EB#$82#$98#$EC#$84#$9C#$20#$EB#$B0#$98#$EA#$B0#$91#$EC#$8A#$B5#$EB#$8B#$88#$EB#$8B#$A4; language: 'Korean'),
    (text: #$ED#$95#$9C#$EA#$B5#$AD#$EB#$A7#$90#$20#$ED#$95#$98#$EC#$8B#$A4#$20#$EC#$A4#$84#$20#$EC#$95#$84#$EC#$84#$B8#$EC#$9A#$94#$3F; language: 'Korean')
  );

// Draw text using font inside rectangle limits
procedure DrawTextBoxed(font: TFont; text: PChar; rec: TRectangle; fontSize, spacing: single; wordWrap: boolean; tint: TColorB);
var
  length, i, k: integer;
  textOffsetY, textOffsetX: single;
  scaleFactor: single;
  state: integer;
  startLine, endLine, lastk: integer;
  codepointByteCount, codepoint, index: integer;
  glyphWidth: single;
begin
  length := TextLength(text);
  textOffsetY := 0.0;
  textOffsetX := 0.0;
  scaleFactor := fontSize / font.baseSize;
  state := 0;
  startLine := -1;
  endLine := -1;
  lastk := -1;

  i := 0;
  k := 0;
  while i < length do
  begin
    codepointByteCount := 0;
    codepoint := GetCodepoint(@text[i], @codepointByteCount);
    index := GetGlyphIndex(font, codepoint);

    if codepoint = $3F then codepointByteCount := 1;
    i := i + (codepointByteCount - 1);

    glyphWidth := 0;
    if codepoint <> 10 then // '\n'
    begin
      if font.glyphs[index].advanceX = 0 then
        glyphWidth := font.recs[index].width * scaleFactor
      else
        glyphWidth := font.glyphs[index].advanceX * scaleFactor;

      if i + 1 < length then glyphWidth := glyphWidth + spacing;
    end;

    if state = 0 then // MEASURE_STATE
    begin
      if (codepoint = 32) or (codepoint = 9) or (codepoint = 10) then // ' ', '\t', '\n'
        endLine := i;

      if (textOffsetX + glyphWidth) > rec.width then
      begin
        if endLine < 1 then endLine := i;
        if i = endLine then endLine := endLine - codepointByteCount;
        if (startLine + codepointByteCount) = endLine then endLine := (i - codepointByteCount);
        state := 1;
      end
      else if (i + 1) = length then
      begin
        endLine := i;
        state := 1;
      end
      else if codepoint = 10 then // '\n'
        state := 1;

      if state = 1 then
      begin
        textOffsetX := 0;
        i := startLine;
        glyphWidth := 0;
        lastk := k - 1;
        k := lastk;
      end;
    end
    else // DRAW_STATE
    begin
      if codepoint = 10 then // '\n'
      begin
        if not wordWrap then
        begin
          textOffsetY := textOffsetY + (font.baseSize + font.baseSize / 2) * scaleFactor;
          textOffsetX := 0;
        end;
      end
      else
      begin
        if (not wordWrap) and ((textOffsetX + glyphWidth) > rec.width) then
        begin
          textOffsetY := textOffsetY + (font.baseSize + font.baseSize / 2) * scaleFactor;
          textOffsetX := 0;
        end;

        if (textOffsetY + font.baseSize * scaleFactor) > rec.height then Break;

        if (codepoint <> 32) and (codepoint <> 9) then // ' ' and '\t'
          DrawTextCodepoint(font, codepoint, Vector2Create(rec.x + textOffsetX, rec.y + textOffsetY), fontSize, tint);
      end;

      if wordWrap and (i = endLine) then
      begin
        textOffsetY := textOffsetY + (font.baseSize + font.baseSize / 2) * scaleFactor;
        textOffsetX := 0;
        startLine := endLine;
        endLine := -1;
        glyphWidth := 0;
        k := lastk;
        state := 0;
      end;
    end;

    textOffsetX := textOffsetX + glyphWidth;
    i := i + 1;
    k := k + 1;
  end;
end;

// Fills the emoji array with random emoji
procedure RandomizeEmoji;
var
  i, start: integer;
begin
  hovered := -1;
  selected := -1;
  start := GetRandomValue(45, 360);

  for i := 0 to EMOJI_PER_WIDTH * EMOJI_PER_HEIGHT - 1 do
  begin
    // 0-179 emoji codepoints (from emoji char array) each 4bytes + null char
    emoji[i].index := GetRandomValue(0, 179) * 5;
    // Generate a random color for this emoji
    emoji[i].color := Fade(ColorFromHSV((start * (i + 1)) mod 360, 0.6, 0.85), 0.8);
    // Set a random message for this emoji
    emoji[i].message := GetRandomValue(0, Length(messages) - 1);
  end;
end;

var
  position, hoveredPos, selectedPos: TVector2;
  i: integer;
  emojiRect: TRectangle;
  messageIdx: integer;
  font: TFont;
  msgText: PChar;
  sz: TVector2;
  msgRect: TRectangle;
  a, b, c: TVector2;
  textRect: TRectangle;
  infoText: PChar;
begin
  SetConfigFlags(FLAG_MSAA_4X_HINT or FLAG_VSYNC_HINT);
  InitWindow(screenWidth, screenHeight, 'raylib [text] example - unicode emojis');

  // Load the font resources
  fontDefault := LoadFont(PChar(GetApplicationDirectory + 'resources/dejavu.fnt'));
  fontAsian := LoadFont(PChar(GetApplicationDirectory + 'resources/noto_cjk.fnt'));
  fontEmoji := LoadFont(PChar(GetApplicationDirectory + 'resources/symbola.fnt'));

  hoveredPos := Vector2Create(0, 0);
  selectedPos := Vector2Create(0, 0);
  selected := -1;

  RandomizeEmoji;

  SetTargetFPS(60);

  while not WindowShouldClose() do
  begin
    // Update
    if IsKeyPressed(KEY_SPACE) then RandomizeEmoji;

    if IsMouseButtonPressed(MOUSE_BUTTON_LEFT) and (hovered <> -1) and (hovered <> selected) then
    begin
      selected := hovered;
      selectedPos := hoveredPos;
    end;

    position := Vector2Create(28.8, 10.0);
    hovered := -1;

    BeginDrawing();
      ClearBackground(RAYWHITE);

      // Draw random emojis in the background
      for i := 0 to EMOJI_PER_WIDTH * EMOJI_PER_HEIGHT - 1 do
      begin
        emojiRect := RectangleCreate(position.x, position.y, fontEmoji.baseSize, fontEmoji.baseSize);

        if not CheckCollisionPointRec(GetMousePosition(), emojiRect) then
        begin
          if selected = i then
            DrawTextEx(fontEmoji, PChar(emojiCodepointsConst + emoji[i].index), position, fontEmoji.baseSize, 1.0, emoji[i].color)
          else
            DrawTextEx(fontEmoji, PChar(emojiCodepointsConst + emoji[i].index), position, fontEmoji.baseSize, 1.0, Fade(LIGHTGRAY, 0.4));
        end
        else
        begin
          DrawTextEx(fontEmoji, PChar(emojiCodepointsConst + emoji[i].index), position, fontEmoji.baseSize, 1.0, emoji[i].color);
          hovered := i;
          hoveredPos := position;
        end;

        if (i <> 0) and (i mod EMOJI_PER_WIDTH = 0) then
        begin
          position.y := position.y + fontEmoji.baseSize + 24.25;
          position.x := 28.8;
        end
        else
          position.x := position.x + fontEmoji.baseSize + 28.8;
      end;

      // Draw the message when an emoji is selected
      if selected <> -1 then
      begin
        messageIdx := emoji[selected].message;
        font := fontDefault;

        // Set correct font for asian languages
        if (TextIsEqual(messages[messageIdx].language, 'Chinese') or
            TextIsEqual(messages[messageIdx].language, 'Korean') or
            TextIsEqual(messages[messageIdx].language, 'Japanese')) then
          font := fontAsian;

        // Calculate size for the message box
        sz := MeasureTextEx(font, messages[messageIdx].text, font.baseSize, 1.0);
        if sz.x > 300 then
        begin
          sz.y := sz.y * (sz.x / 300);
          sz.x := 300;
        end
        else if sz.x < 160 then
          sz.x := 160;

        msgRect := RectangleCreate(selectedPos.x - 38.8, selectedPos.y, 40 + sz.x, 60 + sz.y);
        msgRect.y := msgRect.y - msgRect.height;

        // Coordinates for the chat bubble triangle
        a := Vector2Create(selectedPos.x, msgRect.y + msgRect.height);
        b := Vector2Create(a.x + 8, a.y + 10);
        c := Vector2Create(a.x + 10, a.y);

        // Don't go outside the screen
        if msgRect.x < 10 then msgRect.x := msgRect.x + 28;
        if msgRect.y < 10 then
        begin
          msgRect.y := selectedPos.y + 84;
          a.y := msgRect.y;
          c.y := a.y;
          b.y := a.y - 10;

          // Swap values
          a := b;
          b := c;
          c := a;
        end;

        if msgRect.x + msgRect.width > screenWidth then
          msgRect.x := msgRect.x - ((msgRect.x + msgRect.width) - screenWidth + 10);

        // Draw chat bubble
        DrawRectangleRec(msgRect, emoji[selected].color);
        DrawTriangle(a, b, c, emoji[selected].color);

        // Draw the main text message
        textRect := RectangleCreate(msgRect.x + 10, msgRect.y + 15, msgRect.width - 20, msgRect.height);
        DrawTextBoxed(font, messages[messageIdx].text, textRect, font.baseSize, 1.0, True, WHITE);

        // Draw the info text below the main message
        infoText := PChar(Format('%s %d characters %d bytes', [
          messages[messageIdx].language,
          GetCodepointCount(messages[messageIdx].text),
          TextLength(messages[messageIdx].text)
        ]));
        sz := MeasureTextEx(GetFontDefault(), infoText, 10, 1.0);
        DrawText(infoText, Trunc(textRect.x + textRect.width - sz.x), Trunc(msgRect.y + msgRect.height - sz.y - 2), 10, RAYWHITE);
      end;

      // Draw the info text
      DrawText('These emojis have something to tell you, click each to find out!', (screenWidth - 650) div 2, screenHeight - 40, 20, GRAY);
      DrawText('Each emoji is a unicode character from a font, not a texture... Press [SPACEBAR] to refresh', (screenWidth - 484) div 2, screenHeight - 16, 10, GRAY);

    EndDrawing();
  end;

  UnloadFont(fontDefault);
  UnloadFont(fontAsian);
  UnloadFont(fontEmoji);
  CloseWindow();
end.
