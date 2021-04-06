# crash

**C**rystal **R**emote **A**ny **S**hell **H**elper

## Installation

`layman -a ubuilds`
`emerge crash` or `make install`

## Usage

Update `/etc/crash.ini` with your redis credits.

You'll need one redis server (v6.2+) available for all the clients.

### Client probe

`/etc/init.d/crash start`
or
`crash` # that's simple

### Server agent
Launch command on all hosts connected:
`crash -l all "touch /tmp/crashed"`

Launch command on several hosts connected:
`crash -l host-1,host-2,mainhost-8 "touch /tmp/crashed"`

Host also can be regexp:
`crash -l ^host.*,^mainhost-8$ "touch /tmp/crashed"`

## Development

`make`

## Contributing

1. Fork it (<https://github.com/uu/crash/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Michael Pirogov](https://github.com/uu) - creator and maintainer
