# FileFairy

My first attempt at a macOS app. Built entirely with Cursor and Xcode. Easily batch-rename folders exported from Apple Photos for chronological sorting. Screenshots below.

# Key Features

- preview pane for the changes that will be made (or skipped)
- confirmation of the changes that will be made (or skipped)
- ability to undo changes if for whatever reason you need to, well, undo
- red font for skipped; green font for changed
- a cute pastel-colored FileFairy icon designed entirely by Cursor

# Problem solving:

A lot of people want (or need) to export their photos out of Apple Photos using the File > Export... command. Unfortunately, this creates folders with completely non-chronological names.

For photos inside an event with no name, it just pulls the date and names the folder in the Month Day, Year format, e.g., September 15, 2024

For photos inside an event with a name, it names the folder as Event Name, Month Day, Year, e.g., Mill Valley, September 17, 2024

Obviously, this doesn't work for sorting and thus finding/viewing your photos/videos chronologically. 

So I used Claude and Cursor to write a bash script (which you can find at FileFairy/FileFairy.sh) -- complete with pretty formatting and text colors) to rename all my folders; it worked great. 

Then I thought ... hm ... I wonder if I can use Cursor + Xcode to write my first-ever macOS app, bearing in mind I had no idea what that invovled! 

Long story short, I finally got it all working, and here it is.

![image](https://github.com/marchoag/FileFairy/blob/main/Screenshots/Screenshot%2001.png)

![image](https://github.com/marchoag/FileFairy/blob/main/Screenshots/Screenshot%2002.png)

![image](https://github.com/marchoag/FileFairy/blob/main/Screenshots/Screenshot%2003.png)

![image](https://github.com/marchoag/FileFairy/blob/main/Screenshots/Screenshot%2004.png)

![image](https://github.com/marchoag/FileFairy/blob/main/Screenshots/Screenshot%2005.png)

## Disclaimer

This software is provided "as is", without warranty of any kind, express or implied. The author shall not be held liable for any damages arising from the use of this software.

Please use this app at your own risk.

