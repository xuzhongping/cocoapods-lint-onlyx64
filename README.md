# cocoapods-lint-onlyx64

屏蔽Cocoapods在Xcode12下的验证arm64模拟器架构问题，使用--onlyx64后将只验证x86-64架构。

## Installation

    $ gem install cocoapods-lint-onlyx64

## Usage

    $ pod lib lint xxx --onlyx64
    $ pod spec lint xxx --onlyx64
    $ pod repo/trunk push xxx --onlyx64
