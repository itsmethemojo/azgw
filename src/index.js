const puppeteer = require('puppeteer');
const url = process.env.GANGWAY_URL;
const email = process.env.AZURE_EMAIL;
const password =process.env.AZURE_PASSWORD;

(async () => {
  const browser = await puppeteer.launch({args: ['--no-sandbox']});
  const page = await browser.newPage();
  await page.goto(url + '/login');
  const azureLoginIcon = '.dex-btn-icon.dex-btn-icon--microsoft';
  await page.waitForSelector(azureLoginIcon);
  await page.click(azureLoginIcon);
  await page.waitForNavigation({waitUntil: 'networkidle2'});
  await page.waitForSelector('#i0116');
  const emailInputField = await page.$('#i0116');
  await emailInputField.type(email);
  await emailInputField.press('Enter');
  await page.waitFor(2000);
  await page.waitForSelector('input[type=password]');
  const bodyHandle = await page.$('body');
  const html = await page.evaluate(body => body.innerHTML, bodyHandle);
  const passwordInputField = await page.$('input[type=password]');
  await passwordInputField.type(password);
  await passwordInputField.press('Enter');
  await page.waitForNavigation({waitUntil: 'networkidle2'});
  const codeBoxesSelector = 'div.code-toolbar';
  const codeBoxesDom = await page.$(codeBoxesSelector);
  const codeBoxes = await page.evaluate((selector) => {
    const codeBoxesNodeList = document.querySelectorAll(selector);
    const anchors = [...codeBoxesNodeList];
    return anchors.map(element => element.innerHTML);
  }, codeBoxesSelector);
  console.log(codeBoxes[1].replace(/<\/?[^>]+(>|$)/g, "").replace(/   Copy/g, "").replace(/&gt;/,'>'));
  await browser.close();
})();
