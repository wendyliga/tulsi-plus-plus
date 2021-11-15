# CHANGELOG

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