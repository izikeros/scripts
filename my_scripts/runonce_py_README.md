# runonce.py

`runonce.py` is a Python script that allows you to run a command only once within a specified interval. It creates lock files to track the execution of the command.

## Prerequisites

- Python 3.x

## Usage

```
usage: runonce.py [options] COMMAND

Run COMMAND but only once per interval. See '$HOME/.runonce-*' for lock files.

options:
    -h, -?      help
    -i MINS     interval in minutes (default 480)
```

## Options

- `-h, -?`: Displays the help message.
- `-i MINS`: Sets the interval in minutes (default is 480 minutes).

## Examples

1. Run a command only once within the default interval of 480 minutes:

   ```shell
   ./runonce.py command-to-run
   ```

2. Run a command only once within a custom interval of 60 minutes:

   ```shell
   ./runonce.py -i 60 command-to-run
   ```

## Lock Files

`runonce.py` creates lock files in the user's home directory (`$HOME`) to track the execution of the command. The lock files are named in the format `.runonce-[MD5_HASH]`, where `[MD5_HASH]` is the MD5 hash of the command being executed.

If a lock file exists for a command, the script will not execute the command again until the specified interval has passed.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
