param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string] $SeedDataFilePath = '.\seed-data.json',

    [Parameter(Mandatory = $false, Position = 1)]
    [string] $RootPageForScrapingUrl = 'https://svetosavlje.org/recnik-spasenja/',

    [Parameter(Mandatory = $false, Position = 2)]
    [string] $RootPageForScrapingRegexForLinks = 'https://svetosavlje\.org/recnik-spasenja/[\d]{1,2}(/)?',

    [Parameter(Mandatory = $false, Position = 3)]
    [string] $DictionaryWordRegex = '(<(b|(strong))>.+<\/(b|(strong))><a name="[\d]+"><\/a><br( \/)*>\n&nbsp;<br( \/)*>)|(<(b|(strong))>.+<a name="[\d]+"><\/a><\/(b|(strong))><br( \/)*>\n&nbsp;<br( \/)*>)'
)

function Add-ParagraphTagToArrayEnd
{
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string[]] $Array
    )

    $ArrayList = [System.Collections.ArrayList]::new()
    [void] $ArrayList.AddRange($Array)
    [void] $ArrayList.Add('</p>')

    return $ArrayList
}

function Add-PositionAnnotationsToMatchedDictionaryWordsWithTerminatingParagraph
{
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $PageContent,

        [Parameter(Mandatory = $true, Position = 1)]
        [object[]] $MatchedDictionaryWords
    )

    $AnnotatedMatchedDictionaryWords = [System.Collections.ArrayList]::new()

    for ($i = 0; $i -lt $MatchedDictionaryWords.Length - 1; ++$i)
    {
        $CurrentElementStartIndex = $PageContent.IndexOf($MatchedDictionaryWords[$i])
        $NextElementStartIndex = $PageContent.IndexOf($MatchedDictionaryWords[$i + 1], $CurrentElementStartIndex)

        $CurrentAnnotatedObject = New-Object PSObject -Property @{
            WordStartIndexInDictionary = $CurrentElementStartIndex
            WordContentLengthInDictionary = $NextElementStartIndex - $CurrentElementStartIndex
        }

        [void] $AnnotatedMatchedDictionaryWords.Add($CurrentAnnotatedObject)
    }

    return $AnnotatedMatchedDictionaryWords
}

function Get-WordTitleFromExtractedContentForWord
{
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $ExtractedContentForWord,

        [Parameter(Mandatory = $false, Position = 1)]
        [string] $RegexToApply = '(<b>)|(<\/b>)|(<strong>)|(<\/strong>)'
    )

    $WordTitle = (($ExtractedContentForWord | `
        Select-String -Pattern $DictionaryWordRegex | `
        Select-Object -ExpandProperty Matches | `
        Select-Object -ExpandProperty Value | `
        Foreach-Object { $_ -split $RegexToApply })[2] `
            -split '<')[0]
    
    return $WordTitle

}

function Get-AnnotatedContentFromExtractedContentForWord
{
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $ExtractedContentForWord,

        [Parameter(Mandatory = $false, Position = 1)]
        [string] $EndOfTitleRegex = '<br( \/)*>\n&nbsp;<br( \/)*>\n'
    )

    $EndOfTitleText = $ExtractedContentForWord | `
        Select-String -Pattern $EndOfTitleRegex | `
        Select-Object -ExpandProperty Matches | `
        Select-Object -ExpandProperty Value
    
    $IndexOfEndOfTitle = $ExtractedContentForWord.IndexOf($EndOfTitleText)

    $ContentForWordWithoutTitle = $ExtractedContentForWord.Substring(
        $IndexOfEndOfTitle + $EndOfTitleText.Length, 
        $ExtractedContentForWord.Length - $IndexOfEndOfTitle - $EndOfTitleText.Length).Trim()

    return $ContentForWordWithoutTitle
}

function Get-FirstSubtitleAndItsTextFromExtractedContentForWord
{
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $ExtractedContentForWord
    )

    $OpeningTagWithB = '<b><i>'
    $OpeningTagWithStrong = '<strong><i>'
    $ClosingTagWithB = '</i></b>'
    $ClosingTagWithStrong = '</i></strong>'
    $EndOfTextSegmentCharacters = "<br />`n&nbsp;<br />"

    $ActualStartOfSubtitleIndex = $null
    $ActualEndOfSubtitleIndex = $null
    $ActualStartOfTextIndex = $null

    if ($ExtractedContentForWord.StartsWith($OpeningTagWithB))
    {
        $ActualStartOfSubtitleIndex = $OpeningTagWithB.Length
        $ActualEndOfSubtitleIndex = $ExtractedContentForWord.IndexOf($ClosingTagWithB)
        $ActualStartOfTextIndex = $ActualEndOfSubtitleIndex + $ClosingTagWithB.Length
    }
    elseif($ExtractedContentForWord.StartsWith($OpeningTagWithStrong))
    {
        $ActualStartOfSubtitleIndex = $OpeningTagWithStrong.Length
        $ActualEndOfSubtitleIndex = $ExtractedContentForWord.IndexOf($ClosingTagWithStrong)
        $ActualStartOfTextIndex = $ActualEndOfSubtitleIndex + $ClosingTagWithStrong.Length
    }

    $SubtitleAndItsTextWithRemainingText = $null

    if (-not [string]::IsNullOrEmpty($ActualStartOfSubtitleIndex))
    {
        $Subtitle = $ExtractedContentForWord.Substring($ActualStartOfSubtitleIndex, 
            $ActualEndOfSubtitleIndex - $ActualStartOfSubtitleIndex)

        $RawText = $ExtractedContentForWord.Substring($ActualStartOfTextIndex). `
            TrimStart('<br />').TrimStart().TrimStart('&nbsp;'). `
            TrimStart('<br />').TrimStart()

        $IndexOfEndOfCharacters = $RawText.IndexOf($EndOfTextSegmentCharacters)

        if (-1 -eq $IndexOfEndOfCharacters)
        {
            $SubtitleAndItsTextWithRemainingText = New-Object PSObject -Property @{
                Subtitle = $Subtitle
                Text = $RawText. `
                    TrimEnd('<br />').TrimEnd().TrimEnd('&nbsp;'). `
                    TrimEnd('<br />').TrimEnd().TrimEnd('<br />')
                RemainingText = ''
            }

            return $SubtitleAndItsTextWithRemainingText
        }

        $Text = $RawText.Substring(0, $IndexOfEndOfCharacters)
        $RemainingText = $RawText.Substring($IndexOfEndOfCharacters). `
            TrimStart('<br( \/)*>').TrimStart().TrimStart('&nbsp;'). `
            TrimStart('<br( \/)*>').TrimStart().TrimEnd('<br( \/)*>')
        
        $SubtitleAndItsTextWithRemainingText = New-Object PSObject -Property @{
            Subtitle = $Subtitle
            Text = $Text
            RemainingText = $RemainingText
        }
    }
    else
    {
        # Handle the case where the title does not start with a subtitle and does not contain it
        if (($ExtractedContentForWord.IndexOf($OpeningTagWithB) -lt 0) `
            -and (($ExtractedContentForWord.IndexOf($OpeningTagWithStrong) -lt 0)))
        {
            $SubtitleAndItsTextWithRemainingText = New-Object PSObject -Property @{
                Subtitle = $null
                Text = $ExtractedContentForWord. `
                    TrimEnd('<br( \/)*>').TrimEnd().TrimEnd('&nbsp;'). `
                    TrimEnd('<br( \/)*>').TrimEnd().TrimEnd('<br( \/)*>')
                RemainingText = ''
            }
        }
        # Handle the case where the title does not start with a subtitle, but does contain it
        else
        {
            $ActualStartOfSubtitleWithBIndex = $ExtractedContentForWord.IndexOf($OpeningTagWithB)
            $ActualStartOfSubtitleWithStrongIndex = $ExtractedContentForWord.IndexOf($OpeningTagWithStrong)
            $ActualStartOfSubtitleIndex = $null

            if ($ActualStartOfSubtitleWithBIndex -gt 0)
            {
                $ActualStartOfSubtitleIndex = $ActualStartOfSubtitleWithBIndex
            }
            else 
            {
                $ActualStartOfSubtitleIndex = $ActualStartOfSubtitleWithStrongIndex
            }

            $SubtitleAndItsTextWithRemainingText = New-Object PSObject -Property @{
                Subtitle = $null
                Text = $ExtractedContentForWord.Substring(0, $ActualStartOfSubtitleIndex). `
                    TrimEnd('<br( \/)*>').TrimEnd().TrimEnd('&nbsp;'). `
                    TrimEnd('<br( \/)*>').TrimEnd().TrimEnd('<br( \/)*>')
                RemainingText = $ExtractedContentForWord.Substring($ActualStartOfSubtitleIndex)
            }
        }
    }

    return $SubtitleAndItsTextWithRemainingText
}


################################################################################
###   Get the content of all pages
################################################################################

$UrlsToScrape = Invoke-WebRequest $RootPageForScrapingUrl `
    | Select-Object -ExpandProperty Links `
    | Select-Object -ExpandProperty Href -Unique `
    | Where-Object { $_ -Match $RootPageForScrapingRegexForLinks }
    | Where-Object { $_ -notmatch '.*\/(2|3)\/$' }

$WordsPerLetters = [System.Collections.ArrayList]::new()

foreach ($Url in $UrlsToScrape)
{
    Write-Host
    Write-Host "################################################################################"
    Write-Host "Getting content from URL: $Url"
    Write-Host "################################################################################"

    $PageContent = Invoke-WebRequest -Uri $Url | `
        Select-Object -ExpandProperty Content
    
    $DictionaryWordMatches = Invoke-WebRequest -Uri $Url | `
        Select-Object -ExpandProperty Content | `
        Select-String -Pattern $DictionaryWordRegex -AllMatches | `
        Select-Object -ExpandProperty Matches | `
        Select-Object -ExpandProperty Value

    $DictionaryWordMatchesList = Add-ParagraphTagToArrayEnd -Array $DictionaryWordMatches

    $AnnotatedMatchedDictionaryWords = Add-PositionAnnotationsToMatchedDictionaryWordsWithTerminatingParagraph `
        -PageContent $PageContent `
        -MatchedDictionaryWords $DictionaryWordMatchesList
    
    $DictionaryWordContent = $AnnotatedMatchedDictionaryWords | `
        Foreach-Object { `
            $PageContent.Substring($_.WordStartIndexInDictionary, $_.WordContentLengthInDictionary) }

    [void] $WordsPerLetters.Add($DictionaryWordContent) 
}

# Flatten the array
$ContentOfWordsPerLetters = $WordsPerLetters | Foreach-Object { $_ }

################################################################################
###   Logically separate the content into word title, subtitles and the text   
################################################################################

$AllScrapedData = [System.Collections.ArrayList]::new()

foreach ($ExtractedContentForWord in $ContentOfWordsPerLetters)
{
    $WordTitle = Get-WordTitleFromExtractedContentForWord -ExtractedContentForWord $ExtractedContentForWord

    Write-Host
    Write-Host "################################################################################"
    Write-Host "Processing content for word: $WordTitle"
    Write-Host "################################################################################"

    $RealContentForWord = Get-AnnotatedContentFromExtractedContentForWord -ExtractedContentForWord $ExtractedContentForWord
    
    $SubtitlesWithItsText = [System.Collections.ArrayList]::new()

    $RemainingText = $RealContentForWord
    do 
    {
        $FirstSubtitleWithItsTextResultAndRemainingText = 
            Get-FirstSubtitleAndItsTextFromExtractedContentForWord -ExtractedContentForWord $RemainingText

        $RemainingText = $FirstSubtitleWithItsTextResultAndRemainingText.RemainingText

        $FirstSubtitleWithItsTextResult = New-Object PSObject -Property @{
            Subtitle = $FirstSubtitleWithItsTextResultAndRemainingText.Subtitle
            Text = @($FirstSubtitleWithItsTextResultAndRemainingText.Text.Split("`n") `
                | Foreach-Object { $_.TrimEnd('<br( \/)*>').TrimEnd('&nbsp;') } `
                | Where-Object { $_.Length -gt 0 })
        }

        [void] $SubtitlesWithItsText.Add($FirstSubtitleWithItsTextResult)
    }
    while (-not [string]::IsNullOrEmpty($RemainingText))

    $ScrapedDataForTitle =  New-Object PSObject -Property @{
        Title = $WordTitle
        SubtitlesWithText = $SubtitlesWithItsText
    }

    [void] $AllScrapedData.Add($ScrapedDataForTitle)
}

################################################################################
###   Output the scraped data into a JSON file   
################################################################################

$AllScraptedDataAsJson = $AllScrapedData | ConvertTo-Json -Depth 5
$AllScraptedDataAsJson | Out-File -FilePath $SeedDataFilePath -Encoding UTF8
