require('babel-register')({
  ignore: (filename) => {
    if (/node_modules/.test(filename) && !/node_modules\/zeppelin/.test(filename)) {
      return true
    }
    return false
  },
})
require('babel-polyfill');

module.exports = {
  networks: {
    development: {
      host: 'localhost',
      port: 8545,
      network_id: '*' // Match any network id
    }
  }
};
