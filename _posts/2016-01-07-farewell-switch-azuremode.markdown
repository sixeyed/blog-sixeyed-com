---
title: Farewell 'Switch-AzureMode' & how to fix your scripts
date: '2016-01-07 15:30:36'
tags:
- powershell
- azure
- arm
---

The dust has settled on the Azure Resource Manager (ARM) model's integration to PowerShell, and in the latest [Azure PowerShell module](https://github.com/Azure/azure-powershell/releases) (version 1.0.2 - which you'll get if you install Azure SDK 2.8), `Switch-AzureMode` is gone.

If you've been waiting for the dust to settle, and kept to scripting with the classic model (AKA 'Azure Service Management'), then your old scripts should all work fine and you can congratulate yourself on being cautious.

But if you pick up a script which was written for ARM using the previous modules, it isn't going to work. The cmdlet `Switch-AzureMode` will be in those scripts, and when you run it under the new SDK you'll get an error:

> The term 'Switch-AzureMode' is not recognized as the name of a cmdlet, function, script file, or operable program.

## But why?

Almost all the ARM (v2) cmdlets differ from their ASM (v1) counterparts, because they need to know which resource group you're using, which will be a mandatory property. But in earlier releases, the equivalent ARM and ASM cmdlets **had the same names**.

So you would run `New-AzureStorageAccount` to create a 'classic' storage account using ASM, and use a different command **also called** `New-AzureStorageAccount` to create a storage account within a resource group using ARM.

Which version of the command gets run depends on the run mode of the PowerShell session, and that's where `Switch-AzureMode` came in:

    #create a 'classic' storage account using ASM:
    Switch-AzureMode AzureServiceManagement
    New-StorageAccount -Location NorthEurope -StorageAccountName myv1storageaccount
    
    #create a v2 storage account using ARM -
    #note we have more mandatory properties:
    Switch-AzureMode AzureResourceManager
    New-AzureStorageAccount -ResourceGroupName myresourcegroup -Name myv2storageaccount -Type Standard_LRS -Location NorthEurope

It was a bit of a mess, and for a time it looked like the resolution would break every existing script (see [this post from Code is a highway](http://www.codeisahighway.com/switch-azuremode-deprecation-how-to-prepare-yourself-for-the-migration-ahead/) - the original idea was to rename all the v1 ASM cmdlets).

## How it works from 1.0.x

The actual approach is still a bit fiddly, but it makes more sense:

- the ASM module is still called _Azure_
- the old v1 cmdlets retain the original names
- the new ARM functionality is in multiple modules all prefixed _AzureRM_, e.g. storage is in _AzureRM.Storage_
- the v2 ARM cmdlets are all renamed to append 'Rm' to the 'Azure' part of the name

So now `New-AzureStorageAccount` is the original ASM cmdlet which will create a classic account; `New-AzureRmStorageAccount` will create a new account in a specified resource group:

    #create a 'classic' storage account using ASM:
    New-StorageAccount -Location NorthEurope -StorageAccountName myv1storageaccount
    
    #create a v2 storage account using ARM:
    New-AzureRmStorageAccount -ResourceGroupName myresourcegroup -Name myv2storageaccount -Type Standard_LRS -Location NorthEurope

## Migrating scripts

When you pick up an 1,100-line PowerShell scripts which is mixing ASM and ARM using `Switch-AzureMode`, you'll need to migrate it to work with the new cmdlets.

If you need to do a lot of it, then you could script this up, but for a one-off, this is the migration approach:

1. Find all the `Switch-AzureMode AzureServiceManagement` statements and comment them out; every Azure cmdlet after that statement until the next mode switch will be ASM and will work with its original name, so they can be left as they are
2. Find all the `Switch-AzureMode AzureResourceManager` statements and comment them out. Every Azure cmdlet after that statement until the next mode switch will be ARM, and will need its name changed, from x-Azure... to x-Azure **Rm**...
3. Run the script and see if it works.

> Depending on the age of the script, there may be other breaking changes you'll need to hunt down

For example, to load an additional provider (in this case for [Azure Stream Analytics](https://azure.microsoft.com/en-gb/documentation/articles/stream-analytics-introduction/)), you may see code like this:

    Switch-AzureMode AzureResourceManager 
    Register-AzureProvider -ProviderNamespace Microsoft.StreamAnalytics 

The simple steps above won't fix that, because the ARM cmdlet's name has changed beyond just adding the 'Rm', it's now `Register-AzureRmResourceProvider`.

The last thing to watch out for when you're migrating scripts is to make sure you use the models consistently for each resource - if you try and run `Remove-AzureStorageAccount` (ASM) on an account created with `New-AzureRmStorageAccount` (ARM), it'll fail and the account will still exist.

<!--kg-card-end: markdown-->