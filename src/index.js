const puppeteer = require('puppeteer')
const fs = require('fs')
const path = require('path')
const url = process.env.GANGWAY_URL
const email = process.env.AZURE_EMAIL
const password = process.env.AZURE_PASSWORD
const write_to_file = 'OUTPUT_FILE' in process.env
const output_file = process.env.OUTPUT_FILE
var overrideConfig
try {
  overrideConfig = JSON.parse(process.env.PUPPETEER_CONFIG)
} catch (exception) {
  overrideConfig = {}
}
const baseConfig = JSON.parse(fs.readFileSync(path.join(__dirname, 'default_config.json'), 'utf8'))
const config = Object.assign(baseConfig, overrideConfig)

// eslint-disable-next-line no-unused-vars
const login = (async () => {
  const browser = await puppeteer.launch({ args: ['--no-sandbox'] })
  const page = await browser.newPage()
  await page.goto(url + '/login')
  const azureLoginIcon = config.selector_login_with_azure_button
  await page.waitForSelector(azureLoginIcon, { timeout: config.default_wait_for_selector_timeout })
  await page.click(azureLoginIcon)
  await page.waitForNavigation({ waitUntil: 'networkidle2', timeout: config.default_wait_for_navigation_timeout })
  await page.waitForSelector(config.selector_azure_email_input_field, { timeout: config.default_wait_for_selector_timeout })
  const emailInputField = await page.$(config.selector_azure_email_input_field)
  await emailInputField.type(email)
  await emailInputField.press('Enter')
  await page.waitFor(2000)
  await page.waitForSelector(config.selector_azure_password_input_field, { timeout: config.default_wait_for_selector_timeout })
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
  if (typeof codeBoxes !== 'undefined' && codeBoxes.length >= config.result_index_kubernetes_code_blocks) {
    if(write_to_file){
      fs.writeFileSync(output_file, codeBoxes[config.result_index_kubernetes_code_blocks - 1].replace(/&gt;/, '>'), 'utf8')
    }
    else{
      console.log(codeBoxes[config.result_index_kubernetes_code_blocks - 1].replace(/&gt;/, '>'))
    }
  } else {
    const bodyHandle = await page.$('body')
    const html = await page.evaluate(body => body.innerHTML, bodyHandle)
    if(write_to_file){
      fs.writeFileSync(output_file, html, 'utf8')
    }
    else{
      console.log(html)
    }
  }
  await browser.close()
})()
