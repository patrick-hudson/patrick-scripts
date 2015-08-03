#!/usr/bin/env php
<?php
/**
* Copyright (c) 2014 Patrick Hudson
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
* @author     Patrick Hudson <phudson2@gmail.com>
* @copyright  2014
* @license    http://opensource.org/licenses/MIT
* @version    1.0
*/

foreach(file("albums.txt") as $line) {
    $line = str_replace(' ', '', $line);
    $line = trim(preg_replace('/\s+/', ' ', $line));
    setAlbum($line);
    //echo $line;
}

function setAlbum($albumid){
        $albumName = $albumid;
        $savePath = "album";
        $contents =  file_get_contents("http://api.imgur.com/2/album/$albumName.json");
        // $contents = file_get_contents("$albumName.json");
        $resp = json_decode($contents, true);
        $album = $resp['album'];
        $title = $album['title'];
        $description = $album['description'];
        $images = $album['images'];
        $total = count($images);
        echo "Title : $title\nDesc : $description\nCount : ".$total."\n";
        $clean = $albumName;
        if($title != '') {
            $clean = preg_replace("/[^a-z0-9\-.]/i", '', $title);
        }
        if(!is_dir($savePath)) {
            mkdir($savePath);
        }
        $clean = $savePath."/".$clean;
        if(!is_dir($clean)) {
            mkdir($clean);
        }
        $lastGood = '';
        $cnt = 0;
        foreach($images as $img) {
            $cnt++;
            $original = $img['links']['original'];
            $filePath = $clean.'/'.$cnt.".".basename($original);
            echo "($cnt/$total) : $original : ";
            if(file_exists($filePath)) {
            $file_size = filesize($filePath);
            $img_size = $img['image']['size'];
                if($file_size == $img_size) {
                    echo "skipping\n";
                    continue;
                }
            }
            echo "fetching\n";
            getURL($original, $filePath);
        }
        echo "Finished downloading album to : $clean\n";
        echo "All Done\n";
}

function getURL($url, $filePath)
{
    $ch = curl_init(); 
    $fh = fopen($filePath, 'w'); 
    curl_setopt($ch, CURLOPT_FILE, $fh); 
    curl_setopt($ch, CURLOPT_URL, $url); 
    curl_exec($ch); 
    if(curl_error($ch)) {
        print_r(curl_error($ch));
        exit(3);
    }
    fflush($fh); 
    fclose($fh);
    curl_close($ch);
}
function fetchAlbumDetails($url)
{
    $ch = curl_init(); 
    curl_setopt($ch, CURLOPT_URL, $url); 
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $ret = curl_exec($ch); 
    if(curl_error($ch)) {
        print_r(curl_error($ch));
        exit(3);
    }
    curl_close($ch);
    return $ret;
}