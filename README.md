# Widget-Shell

## Array Display

`array_display.sh` is a script who take on input a file or a variable and display it under a table array (like linux command `column`)

See script's options (`-h` option) :

```
--help    : Help

--input   : Input File|Variable
--column  : Column to Display      [Default=all] (Ex: 1,3|1-3|2)
--header  : Display Header         [Default=No]
--sort    : Sort Column            [Default=No]  (Ex: k2,n,r)
--sep     : Input Separator        [Default=';']
--mrg     : Margin between Column  [Default=1]
```

### Examples

```bash
INPUT_VAR="raw1;raw2;raw3\nraw4;raw5;raw6"
```

Display with semicolon (default) separator :

```
$ ./array_display.sh --input $INPUT_VAR
 | raw1 | raw2 | raw3
 | raw4 | raw5 | raw6
```

With header :

```
$ ./array_display.sh --input $INPUT_VAR --header
 | raw1 | raw2 | raw3
 | ---- | ---- | ----
 | raw4 | raw5 | raw6
```

With custom marge :

```
$ ./array_display.sh --input $INPUT_VAR --mrg 5
 | raw1     | raw2     | raw3
 | raw4     | raw5     | raw6
```


## Load Bar

`load_bar_display.sh` is a small script which allows to display a progression bar.

He take on arguments :
 * Total Object
 * Current Object
 * Message to display next to the bar **WARNING:String with no space/tab: `_` replace by space**
 * Bar size (Default:15)


### Examples

Load bar on loop :

```
$ for i in {1..32}; do bash load_bar_display.sh 32 $i "My_Bar"; done
  My Bar        : [ooo............] 21% [007/032]
  My Bar        : [ooooo..........] 37% [012/032]
  My Bar        : [ooooooo........] 53% [017/032]
  My Bar        : [ooooooooooo....] 75% [024/032]
  My Bar        : [oooooooooooooo.] 93% [030/032]
  My Bar        : [ooooooooooooooo] 100% [032/032] [done]
```

With Custom size (Default:15) :

```
$ for i in {1..32}; do bash load_bar_display.sh 32 $i "My_Bar"; done
  My Bar        : [ooooo.........................] 18% [006/032]
  My Bar        : [oooooooooo....................] 34% [011/032]
  My Bar        : [ooooooooooooooo...............] 53% [017/032]
  My Bar        : [ooooooooooooooooooooo.........] 71% [023/032]
  My Bar        : [ooooooooooooooooooooooooooo...] 90% [029/032]
  My Bar        : [oooooooooooooooooooooooooooooo] 100% [032/032] [done]
```
