chronos-pkg
============

Packaging utilities for Chronos.

* Install FPM.

```bash
gem install fpm
```

* Install packaging tools particular to your platform.

```bash
yum install rpm-build                   ## On RedHat/CentOS/Fedora
```

* Install Maven and an appropriate JDK to build Chronos.

* (Optional) Checkout the branch of Chronos you'd like to build in the
  `chronos` directory (maintained as a submodule).

* For make targets and further instructions:

```bash
make help
```

# Testing

Shakedown testing under [tests/system](tests/system) was added to test Chronos in an DCOS env.

It has been used to test Chrono 3.0.1 and runs through the basic chronos tutorial.

To run:

1. Install [Shakedown](https://github.com/dcos/shakedown)
1. Create a DCOS and setup from CLI
1. Run shakedown test `shakedown tests/`

*note:*  To run a specific test:  `shakedown tests/`
