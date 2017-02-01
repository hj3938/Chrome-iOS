## An ultra-modern, privacy + feature rich mobile Chrome

On Jan 31, Google OpenSourced the Chromium port for iOS. I was estatic, and got it right away, adding some UI and UX tweaks and placing in some new features.  
  
I'll add more as I go, but right now the main goals are:
- a flatter, more dynamic and ultra-modern UI (inspired by hyperMaterial design elements)
- features (ext) that note privacy and limited data transfer
- destruction of non-essential components and anim improvements

Mostly, just for my taste.

## Instillation and building for the unitiated

Follow the [official Chromium article](https://chromium.googlesource.com/chromium/src/+/master/docs/ios_build_instructions.md#Running-apps-from-the-commandline), or my tutorial below:

### Reqs
1. Be on a Mac. Duh.
2. Be on a new(er) Mac. Duh.
3. Be on a new(er) Mac with Xcode. Duh.
4. **Depot Tools**  
  Clone Google's depot tools:  
  ``` bash 
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
  ```  
    
  export the path, and place it in your `~/.bashrc`, unless you want to do this in every new instance of Terminal:  
  ``` bash
  $ export PATH="$PATH:/path/to/depot_tools"
  ```
  
### Grabbing the repo
You have two options:  
&nbsp;&nbsp;(1) git clone this repo directly, or  
&nbsp;&nbsp;r(2) create + fetch chromium, and then git clone this repo in the iOS folder.

The second one is recommended, and is easily done:
```bash
mkdir chromium && cd chromium
# now we use Google's fetch to grab that iOS stuff
fetch ios && cd src

# (optionally) you can now fetch the repo
cd iOS
git init
git remote add origin https://github.com/ayazhafiz/Chrome-iOS.git
git fetch
git checkout -t origin master
```

### Building
*You* __must__ *be in the src directory*  
All of our builds will belong to a directory named `out`. Using `depot_tools`' `gn`, we can generate a build with an appropriate Xcode workspace:
```bash
       # we're building for iOS
gn gen --target_os="ios" out/Default
                         # any dir is fine, a.l.a it's under out
```
Alternatively, run the pre-defined Python script that will create a debug, official, profile, and release build dir:
```bash
python ios/build/tools/setup-gn.py
```

### Release
For obvious reasons, you will never be able to publish this on the App Store. But have some fun! Your phone is yours; make Chrome yours too!
