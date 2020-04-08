const puppeteer = require('puppeteer')
const fs = require('fs')
const url = process.env.GANGWAY_URL
const email = process.env.AZURE_EMAIL
const password = process.env.AZURE_PASSWORD
var override_config;
//TODO rename AZGW_CONFIG
try {
  override_config = JSON.parse(process.env.AZGW_CONFIG);
}
catch (exception) {
  override_config = {};
}
const base_config = JSON.parse(fs.readFileSync(__dirname + '/default_config.json', 'utf8'));
const config = Object.assign(base_config, override_config);

//TODO test availability of gangway/dex to avoid stucking in a promise because some url cannot be reached
//TODO add debug output
// eslint-disable-next-line no-unused-vars
const login = (async () => {
  const browser = await puppeteer.launch({ args: ['--no-sandbox'] })
  const page = await browser.newPage()
  await page.goto(url + '/login')
  const azureLoginIcon = config.selector_login_with_azure_button
  await page.waitForSelector(azureLoginIcon, {timeout: config.default_wait_for_selector_timeout})
  await page.click(azureLoginIcon)
  await page.waitForNavigation({ waitUntil: 'networkidle2', timeout: config.default_wait_for_navigation_timeout })
  await page.waitForSelector(config.selector_azure_email_input_field, {timeout: config.default_wait_for_selector_timeout})
  const emailInputField = await page.$(config.selector_azure_email_input_field)
  await emailInputField.type(email)
  await emailInputField.press('Enter')
  await page.waitFor(2000)
  await page.waitForSelector(config.selector_azure_password_input_field, {timeout: config.default_wait_for_selector_timeout})
  const passwordInputField = await page.$(config.selector_azure_password_input_field)
  await passwordInputField.type(password)
  await passwordInputField.press('Enter')
  await page.waitForNavigation({ waitUntil: 'networkidle2', timeout: config.default_wait_for_navigation_timeout })
  const codeBoxesSelector = config.selector_kubernetes_code_blocks
  const codeBoxes = await page.evaluate((selector) => {
    const codeBoxesNodeList = document.querySelectorAll(selector)
    const anchors = [...codeBoxesNodeList]
    return anchors.map(element => element.innerHTML)
  }, codeBoxesSelector)
  if (typeof codeBoxes !== "undefined" && codeBoxes.length >= config.result_index_kubernetes_code_blocks){
    console.log(codeBoxes[config.result_index_kubernetes_code_blocks - 1].replace(/&gt;/, '>'))
  }
  else{
    const bodyHandle = await page.$('body');
    const html = await page.evaluate(body => body.innerHTML, bodyHandle)
    console.log(html)
  }
  await browser.close()
})()
