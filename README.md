# ManaGuide-maintainer

ManaGuide-maintainer is a command line interface (CLI) non-iOS/ mac OS program written in the Swift programming language. It is used to update the database of [Mana Guide](https://github.com/vito-royeca/ManaGuide).

## Usage

    ManaGuide-maintainer --host <host> --port <port> --database <database> --user <user> --password <password> --full-update <full-update>

    OPTIONS:
      --host <host>           Database host.
      --port <port>           Database port.
      --database <database>   Database name.
      --user <user>           Database user.
      --password <password>   Database password.
      --full-update <full-update>
                              Full update: true | false
      -h, --help              Show help information. 

## Building

    $ swift build -c release
    $ cp .build/release/ManaGuide-maintainer /usr/local/bin/ManaGuide-maintainer

## Author

Vito Royeca
https://vitoroyeca.com
vito.royeca@gmail.com

