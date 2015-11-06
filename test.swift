#!/usr/bin/env xcrun swift
import Foundation

let LOCALE_ID = "en_US_POSIX"
let ISO8601_FORMAT = "yyyy-MM-ddTHH:mm:ssZ"
let INPUT_FORMAT = "yyyy-MM-dd"
let TIMEZONE = "GMT"

func nDaysAgo(nDaysAgo: Int, fromDate: NSDate) -> NSDate? {
    if let ret =  NSCalendar.currentCalendar().dateByAddingUnit(.Day, value: -nDaysAgo, toDate: fromDate, options: NSCalendarOptions(rawValue: 0)) {
        return ret
    }
    return nil
}

func partial(f: (Int, NSDate) -> NSDate?, defaultDate: NSDate) -> (Int) -> NSDate? {
    return { f($0, defaultDate) }
}

func getFormatter(format: String) -> NSDateFormatter {
    let dateFormatter = NSDateFormatter()
    dateFormatter.locale = NSLocale(localeIdentifier: LOCALE_ID)
    dateFormatter.timeZone = NSTimeZone(abbreviation: TIMEZONE)
    dateFormatter.dateFormat = format

    return dateFormatter
}

func date2String(date: NSDate) -> String? {
    return getFormatter(ISO8601_FORMAT).stringFromDate(date)
}

func string2Date(string: String) -> NSDate? {
    return getFormatter(INPUT_FORMAT).dateFromString(string)
}

func main(argv: [String]) {
    if argv.count < 2 || argv.count > 3 {
        print("ERROR: Bad Input")
        return
    }

    guard let n = Int(argv[1]) else {
        print("ERROR: First param must be a integer.")
        return
    }

    let rollOnDate = {
        (date: NSDate) in
        guard let dateStr = date2String(date) else {
            return
        }

        let nbCommits = Int(arc4random_uniform(10) + 1)

        (1...nbCommits).map({
            _ in
            let task = NSTask()
            task.launchPath = "/bin/bash"
            task.arguments = ["-c", "echo \"\(date): \(arc4random_uniform(UInt32.max))\" > realwork.txt; git add realwork.txt; git commit --date=\"\(dateStr)\" -m 'update'; git push;"]
            task.launch()
            task.waitUntilExit()
        })
    }

    let roll = {
        (startDate: NSDate, n: Int) in
        (1...n).map(partial(nDaysAgo, defaultDate: startDate)).filter({$0 != nil}).map({$0!}).map(rollOnDate)
    }

    if argv.count == 2 {
        let startDate = NSDate()
        roll(startDate, n)
    } else if argv.count == 3 {
        guard let startDate = string2Date(argv[2]) else {
            return
        }
        roll(startDate, n)
    }
}

main(Process.arguments)
