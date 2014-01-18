hashrate
========

Bitcoin mining profit calculator based on difficulty. 

Uses difficulty data from the [blockchain.info API](https://blockchain.info/charts/difficulty) and extrapolates data with simple linear regression (via. [linefit](https://github.com/escline/linefit)).

I strongly encourage the user to verify these results with the [bitcoinx profit calculator](http://www.bitcoinx.com/profit/).

Note: this calculator currently uses a static 25 bitcoin reward. It won't work very well for calculations [before 2013 or after 2016](https://en.bitcoin.it/wiki/Controlled_Currency_Supply). 

Note also that I designed this to be used in Rails, so it caches the json from blockchain's API for six hours before requesting it again.

## Example Usage

How much would a 100 GH/s machine have earned running for the last six months?
  
    >> require 'hashrate'
    => true
    >> now = Time.new.to_i
    >> Hashrate.earning(now - (60 * 60 * 24 * 30 * 6), now, 1000 * Hashrate::GH)
    => 201.08229099734106

201 bitcoins - wow!

What do we expect this machine to earn in the next six months?

    >> Hashrate.earning(now, now + (60 * 60 * 24 * 30 * 6), 1000 * Hashrate::GH)
    => 9.280482914219407

Only 9 bitcoins - ouch. Should've started running it six months ago.
