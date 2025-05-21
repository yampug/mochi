package rb.nebula.utils

enum class HtmlTag {
    // Structure & Metadata
    HTML, HEAD, TITLE, BODY,
    // Text & Formatting
    H1, H2, H3, H4, H5, H6, P,
    BR, HR, PRE, BLOCKQUOTE,
    STRONG, EM, B, I, U, S,
    SMALL, SUB, SUP,
    SPAN, DIV,
    // Lists
    UL, OL, LI, DL, DT, DD,
    // Links & Media
    A, IMG, VIDEO, AUDIO, SOURCE, TRACK,
    // Tables
    TABLE, THEAD, TBODY, TFOOT, TR, TH, TD, CAPTION, COLGROUP, COL,
    // Forms
    FORM, INPUT, LABEL, BUTTON, SELECT, OPTION, OPTGROUP, TEXTAREA,
    FIELDSET, LEGEND,
    // Scripting & Embedding
    SCRIPT, NOSCRIPT, STYLE,
    IFRAME, EMBED, OBJECT, PARAM,
    // Sections
    HEADER, FOOTER, MAIN, NAV, SECTION, ARTICLE, ASIDE,
    // Details & Dialog
    DETAILS, SUMMARY, DIALOG,
    // Other
    ADDRESS, CITE, CODE, DATA, DFN, KBD, MARK, METER, OUTPUT, PROGRESS, Q, RUBY, RT, RP, SAMP, TIME, VAR, WBR,
    // Obsolete or less common
    // (You might choose to exclude these depending on your use case)
    BASE, BASEFONT, BGSOUND, BIG, BLINK, CENTER, DIR, FONT, FRAME, FRAMESET, ISINDEX, LISTING, MARQUEE, MENU, MULTICOL, NOBR, NOEMBED, NOFRAMES, PLAINTEXT, SPACER, STRIKE, TT, XMP
}