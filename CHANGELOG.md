# CHANGELOG

## 0.12.0
<h2>Tulsi++ 0.12.0 </h2>
<ol> 
    <li>Use New Build System by default</li>
    <li>Fix Xcode 14 issues</li>
    <li>Fix New Build System Issues</li>
    <li>Bump minimum macos version to 11.0</li>
    <li>Sync with Upstream</li>
</ol>

----

## 0.11.0
<h2>Tulsi++ 0.11.0 </h2>
<ol> 
    <li>Sync with upstream</li>
</ol>

----
## 0.10.1
<h2>Tulsi++ 0.10.1 🕌</h2>
<h4>DocC Improvement:</h4> 
<ol> 
    <li>Support .docc bundle</li>
    <li>Only generate docc target when tags docc is detected on bazel rule</li>
</ol>

<h4>Other Improvement:</h4> 
<ol> 
    <li>Clean(cmd+k) will clean all derivedData build directory</li>
    <li>Support XCFramework</li>
</ol>

----

## 0.10.0
<h2>Tulsi++ 0.10.0 🕌</h2>
<h4>Improvement:</h4> 
<ol> 
    <li>Add new target to generate DocC from tulsi's generated xcodeproj</li>
    
</ol>

----
## 0.9.2
<h2>Tulsi++ 0.9.2 </h2>
<h4>Bug Fix:</h4> 
<ol> 
    <li>Fix crash on Xcode 13.3 on Macos 12.3</li>
</ol>

<h4>Sync with Upstream:</h4> 
<ol> 
    <li>Migrate python script to python3</li>
    <li>Add support for stub binaries</li>
    <li><a href="https://github.com/wendyliga/tulsi-plus-plus/pull/63">More</a></li>
</ol>

----

## 0.9.1
<h2>Tulsi++ 0.9.1 </h2>
<h4>Improvement:</h4> 
<ol> 
    <li>Inject SRCROOT on environment by default, to support XCTSourceCodeLocation swizzle</li>
</ol>

----

## 0.9.0
<h2>Tulsi++ 0.9.0 </h2>
<h4>Improvement:</h4> 
<ol> 
    <li>Unit Test is buildable(⌘+B) now</li>
    <li>Exclude Bazel Tulsi internal directory from real group path</li>
    <li>Change default sort to label title on target selection window</li>
</ol>

----

## 0.8.0
<h2>Tulsi++ 0.8.0 </h2>
<h4>Improvement:</h4> 
<ol> 
    <li>Add option to not open xcode after generate</li>
    <li>Better Xcode 13 auto complete referencing</li>
</ol>
<h4>Bug Fix:</h4> 
<ol> 
    <li>Fix not all PRODUCT_NAME use module name on TestRunner scheme</li>
</ol>

----

## 0.7.3
<h2>Tulsi++ 0.7.3 🎉 </h2>
<h4>Sync with Upstream:</h4> 
<ol> 
    <li>Add UseLegacyBuildSystem option to swap between new/old build systems</li>
    <li>Fix signing of test runners with Xcode 13</li>
    <li>Improve performance of fetching build/bzl files for a project</li>
    <li>more <a href="https://github.com/wendyliga/tulsi-plus-plus/pull/46">here</a></li>
</ol>

----

## 0.7.2
<h2>Tulsi++ 0.7.2 🎅 </h2>
<h4>Improvement:</h4> 
<ol> 
    <li>use universal binary</li>
</ol>

----

## 0.7.1
<h2>Tulsi++ 0.7.1 🎅 </h2>
<h4>Bug Fixes:</h4> 
<ol> 
    <li>fix fail building uitest on legacy build</li>
</ol>

----

## 0.7.0
<h2>Tulsi++ 0.7.0 🎅 </h2>
<h4>Bug Fixes:</h4> 
<ol> 
    <li>fix xcodeproj_output_dir sometimes isn't saved to disk</li>
    <li>fix recent document on splash window sometimes is empty</li>
</ol>

<h4>Improvements:</h4> 
<ol> 
    <li>Now Xcode 13 auto import should suggest same name with modulemap(use modulemap name for PRODUCT_NAME)</li>
    <li>change button title to "Save", when tapping change xcodeproj_output_dir</li>
    <li>save delete_previous_xcodeproj flag to disk</li>
    
</ol>

----

## 0.6.2
<h2>Tulsi++ 0.6.2 🔥 </h2>
<h4>Change:</h4> 
<ol> 
    <li>native apple silicon binary</li>
</ol>

----

## 0.6.1
<h2>Tulsi++ 0.6.1 🔥 </h2>
<h4>Fix:</h4> 
<ol> 
    <li>as we use bazel to take care of signing, silent Xcode New Build System mandatory signing error.</li>
</ol>

----

## 0.6.0
<h2>Tulsi++ 0.6.0 🔥 </h2>
<h4>What's new:</h4> 
<ol> 
    <li>By default, will use Xcode New Build System</li>
    <li>Add Option to use Legacy Build System, false by default</li>
</ol>

<h4>New Build System Fixes:</h4> 
<ol> 
    <li>unit test will build & test successfully on Xcode 13</li>
    <li>Fix issue where unit test failure doesn't pin to the exact code line</li>
    <li>eliminate error couldn't find framework folder</li>
    <li>Xcode will properly indexing the whole codebase in the background</li>
</ol>

----

## 0.5.3
<h2>Tulsi++ 0.5.3 🔨 </h2>
<h4>What's new:</h4> 
<ol> 
    <li>update appcast to use new binary url from new release system</li>
</ol>

----

## 0.5.2
<h2>Tulsi++ 0.5.2 🔨 </h2>
<h4>What's new:</h4> 
<ol> 
    <li>sync with upstream including but not limited to:</li>
    <li>support ios_sim_arm64 cpu type</li>
    <li>point external path into stable external directory</li>
    <li>fix broken external BuildLabel filename parsing</li>
</ol>

----

## 0.5.1
<h2>Tulsi++ 0.5.1 🔨 </h2>
<h4>What's new:</h4> 
<ol> 
    <li>fix xcodeproj path cleared after reopen</li>
</ol>

----

## 0.5.0
<h2>Tulsi++ 0.5.0 🔨 </h2>
<h4>What's new:</h4> 
<ol> 
    <li>xcodeproj output will be saved on tulsiproj, so the value will be unique per tulsiproj</li>
    <li>add `Changelogs` on menu bar</li>
    <li>add options to open previous project without generate</li>
</ol>

----

## 0.4.4
<h2>Tulsi++ 0.4.4 🔨 </h2>
<h4>What's new:</h4> 
<ol> 
    <li>Fix set directory when generate will never end</li>
    <li>Improve path set on generate will be saved for future generate</li>
</ol> 

----

## 0.4.3
<h2>Tulsi++ 0.4.3 🔨 </h2>
<h4>What's new:</h4> 
<ol> 
    <li>Add option to set output directory for xcodeproj</li>
</ol> 

----

## 0.4.2
<h2>Tulsi++ 0.4.2 🔨 </h2>
<h4>What's new:</h4> 
<ol> 
    <li>New file will be located on correct folder. thanks to <a src="https://github.com/ahmadnbl">@ahmadnbl</a></li>
    <li>up several gems dependency version because of vurnability issues detected by dependabot</li>
</ol> 

----

## 0.4.1
<h2>Tulsi++ 0.4.1 🔨 </h2>
<h4>What's new:</h4> 
<ol> 
    <li>Reduce almost 70% appsize from 20mb to 8mb</li>
    <li>Improve check-for-update logic</li>
    <li>Update icon style to big sur</li>
    <li>Add CI build mode</li>
</ol> 

----

## 0.4.0
<h2>Tulsi++ 0.4.0 🔨 </h2>
<h4>What's new:</h4> 
<ol> 
    <li>Tulsi++'s releases will be notorized</li>
</ol> 

----

## 0.3.0
<h2>Tulsi++ 0.3.0 🔨 </h2>
<h4>What's new:</h4> 
<ol> 
    <li>Use Sparkle to support OTA update</li>
    <li>Rebrand Tulsi++ from Tulsi source</li>
    <li>Remove unneccessary file on repo</li>
    <li>Add OSS License page on Help</li>
</ol> 

----