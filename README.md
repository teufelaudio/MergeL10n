# MergeL10n

## Usage

### pseudo-to-languages

```
# first generate the pseudo-language
genstrings -o MyApp/MyApp/L10n/zz.lproj YourSwiftFilesWithLocalizableStrings.swift

# then
MergeL10n pseudo-to-languages \
    --languages="en,de,zh-Hans"
    --base-paths="MyApp/MyApp/L10n"
    --development-language="en"
```

This will use zz.lproj as source-of-truth and delete any key in the other languages that are no longer in use.
It will also add all new keys for the development language file.
The comments and keys on zz are the source-of-truth, so the developer controls those. The values, however, are never replaced.

Example:

Initial state
```
zz:
    /* Developer comment for A */
    "KeyA"="";

    /* Developer comment for B */
    "KeyB"="";

    /* Developer comment for D */
    "KeyD"="";

    /* Developer comment for F */
    "KeyF"="";

en:
    "KeyA"="Some english key for A";

    /* Translator comment for B */
    "KeyB"="Some english key for B";

    "KeyC"="Some english key for C";

    "KeyE"="Some english key for E";
```

Resulting state
```
en:
    /* Developer comment for A */
    "KeyA"="Some english key for A";

    /* Developer comment for B */
    "KeyB"="Some english key for B";

    /* Developer comment for D */
    "KeyD"="";

    /* Developer comment for F */
    "KeyF"="";
```

As you can see:
- Keys C and E were deleted because they are no longer in use (zz tells the source-of-truth for keys)
- Keys D and F were added because they were introduced by developer (zz tells the source-of-truth for keys)
- New keys will have empty value because "en" is the development language. For other languages nothing will be added.
- Removed keys have their values lost, as they are no longer needed
- Commends from code will overwrite any comment from translators in your language files.
- It will ALWAYS sort alphabetically to reduce merge conflicts

## Parameters and environment variables

### pseudo-to-languages

- Optional parameter `--languages="en,de,zh-Hans"`, if not found it will look in the environment variables for SUPPORTED_LANGUAGES.
- Optional parameter `--base-paths="MyApp/MyApp/L10n,MyLib/MyLib/L10n"`, if not found it will look in the environment variables for L10N_BASE_PATHS
- Optional parameter `--development-language="en"`, if not found it will use English

For Environment Variables you can create a ".env" file in the folder where you run the MergeL10n command (it doesn't have to be the same folder where the executable is in, but the folder you are when you execute it). This file is a key-value list with each key-value pair separated by "=" and one pair per line (\n line break).
