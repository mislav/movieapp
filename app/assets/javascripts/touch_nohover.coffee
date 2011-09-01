if 'createTouch' of document
  ignore = /:hover\b/
  try
    for stylesheet in document.styleSheets
      idxs = []
      # detect hover rules
      for rule, idx in stylesheet.cssRules
        if rule.type is CSSRule.STYLE_RULE and ignore.test(rule.selectorText)
          idxs.unshift idx

      # delete hover rules
      stylesheet.deleteRule idx for idx in idxs
