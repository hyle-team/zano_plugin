module.exports = (targetOptions, indexHtmlContent) => {
  //TODO: Update version chrome
  // It is important to replace type="module" with defer.
  // Without this, the application will not start.
  indexHtmlContent = indexHtmlContent.toString().replace(/type="module"/gm, 'defer');
  return indexHtmlContent;
};
