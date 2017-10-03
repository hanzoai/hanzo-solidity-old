require('babel-register');
require('babel-polyfill');

module.exports = {
  mocha: {
    compilers: 'babel-core/register'
  },
  networks: {
    development: {
      host: 'localhost',
      port: 8545,
      network_id: '*' // Match any network id
    }
  }
};
