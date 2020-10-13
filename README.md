# Cx Disk Maintenance Scrips



## zip-cxsrc-scans.ps1

Zips the Sast scans source code folders that are inside the `CxSrc` folder.

The scans are compressed by order of the **creation time** ignoring the first **N** scans determined by the parameter `-keep`.

| Parameters          | Description                                      | Required | Type    | Default |
| ------------------- | ------------------------------------------------ | -------- | ------- | ------- |
| `-path`             | The path where the scans are located             | true     | String  | n/a     |
| `-keep`             | The number of last scans that will not be zipped | false    | Integer | 50      |
| `-project`          | The id of the project that is going to be zipped | false    | Integer | all     |
| `-keepSourceFolder` | Option to keep the original folder               | false    | Boolean | false   |

The script performs the following tasks:

1. Get the scans list from `CxSRC` folder
2. Filter them by project (if the `-project` was specified)
3. Order the le list by creation time (desc)
4. Check if the scan should be skipped or not (according to his project id and the `-keep` parameter )
5. Zips the scan content and places it on the folder's root as a temporary file
6. Delete the original scan folder content
7. Moves the zip file to the original folder

ex.

```powershell
zip-cxsrc-scans.ps1 -path 'C:\CxSRC' -keep 2 -project 1002
```



## undo-zip-cxsrc-scans.ps1

Reverts the `zip-cxsrc-folder.ps1` script action.

| Parameters | Description                          | Required | Type   | Default |
| ---------- | ------------------------------------ | -------- | ------ | ------- |
| -path      | The path where the scans are located | true     | String | n/a     |

The script performs the following tasks:

1. Get the scans list from `CxSRC` folder
2. Looks for a folder named `content.zip` in each scan folder
3. If the file was found, it will be unzipped on the scan root folder
4. Delete the zip file

ex.

```powershell
undo-zip-cxsrc-scans.ps1 -path 'C:\CxSRC'
```


## TODO

- [ ] Add more verbose output to the user (with deletion details showing some action).
