import Foundation
import SQLite3

class BibleDatabase {
    static let shared = BibleDatabase()
    private var database: OpaquePointer?
    
    private init() {
        setupDatabase()
    }
    
    deinit {
        sqlite3_close(database)
    }
    
    private func setupDatabase() {
        guard let dbURL = Bundle.main.url(forResource: "BibleDB", withExtension: "sqlite") else {
            print("BibleDB.sqlite 파일을 찾을 수 없습니다.")
            return
        }
        
        let result = sqlite3_open(dbURL.path, &database)
        if result != SQLITE_OK {
            print("데이터베이스 열기 실패: \(result)")
            return
        }
    }
    
    // MARK: - 성경 책 조회
    func getAllBooks(versionCode: String = "KRV") -> [BibleBook] {
        var books: [BibleBook] = []
        
        let query = "SELECT * FROM bible_book WHERE version_code = ? ORDER BY book_order"
        
        var statement: OpaquePointer?
        let result = sqlite3_prepare_v2(database, query, -1, &statement, nil)
        
        if result == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (versionCode as NSString).utf8String, -1, nil)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                let bookId = String(cString: sqlite3_column_text(statement, 0))
                let bookCode = String(cString: sqlite3_column_text(statement, 1))
                let bookOrder = Int(sqlite3_column_int(statement, 2))
                let bookName = String(cString: sqlite3_column_text(statement, 3))
                let versionCode = String(cString: sqlite3_column_text(statement, 4))
                
                // chapters 정보는 별도 쿼리로 가져와야 함
                let chapters = getChaptersForBook(bookCode: bookCode, versionCode: versionCode)
                
                let bibleBook = BibleBook(
                    id: bookId,
                    name: bookName,
                    code: bookCode,
                    order: bookOrder,
                    chapters: chapters
                )
                
                books.append(bibleBook)
            }
        }
        
        sqlite3_finalize(statement)
        return books
    }
    
    // MARK: - 성경 역본 조회
    func getAllVersions() -> [BibleVersion] {
        var versions: [BibleVersion] = []
        
        let query = "SELECT * FROM bible_version ORDER BY version_code"
        
        var statement: OpaquePointer?
        let result = sqlite3_prepare_v2(database, query, -1, &statement, nil)
        
        if result == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let versionCode = String(cString: sqlite3_column_text(statement, 0))
                let versionName = String(cString: sqlite3_column_text(statement, 1))
                let language = String(cString: sqlite3_column_text(statement, 2))
                
                let bibleVersion = BibleVersion(
                    id: versionCode.lowercased(),
                    name: versionName,
                    code: versionCode,
                    language: language
                )
                
                versions.append(bibleVersion)
            }
        }
        
        sqlite3_finalize(statement)
        return versions
    }
    
    // MARK: - 책의 장 수 조회
    func getChaptersForBook(bookCode: String, versionCode: String) -> Int {
        let query = "SELECT MAX(chapter) FROM bible_verse WHERE book_code = ? AND version_code = ?"
        var statement: OpaquePointer?
        let result = sqlite3_prepare_v2(database, query, -1, &statement, nil)
        if result == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (bookCode as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (versionCode as NSString).utf8String, -1, nil)
            if sqlite3_step(statement) == SQLITE_ROW {
                let chapters = Int(sqlite3_column_int(statement, 0))
                sqlite3_finalize(statement)
                return chapters
            }
        }
        sqlite3_finalize(statement)
        return 0
    }
    
    // MARK: - 특정 장의 구절 수 조회
    func getVersesForChapter(bookCode: String, chapter: Int, versionCode: String = "KRV") -> Int {
        let query = "SELECT MAX(verse) FROM bible_verse WHERE book_code = ? AND chapter = ? AND version_code = ?"
        
        var statement: OpaquePointer?
        let result = sqlite3_prepare_v2(database, query, -1, &statement, nil)
        
        if result == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (bookCode as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 2, Int32(chapter))
            sqlite3_bind_text(statement, 3, (versionCode as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_ROW {
                let verses = Int(sqlite3_column_int(statement, 0))
                sqlite3_finalize(statement)
                return verses
            }
        }
        
        sqlite3_finalize(statement)
        return 0
    }
    
    // MARK: - 성경 구절 조회 메서드들
    
    func getVerse(bookCode: String, chapter: Int, verse: Int, versionCode: String = "KRV") -> BibleVerse? {
        let query = "SELECT * FROM bible_verse WHERE book_code = ? AND chapter = ? AND verse = ? AND version_code = ?"
        
        var statement: OpaquePointer?
        let result = sqlite3_prepare_v2(database, query, -1, &statement, nil)
        
        if result == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (bookCode as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 2, Int32(chapter))
            sqlite3_bind_int(statement, 3, Int32(verse))
            sqlite3_bind_text(statement, 4, (versionCode as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_ROW {
                let verseId = String(cString: sqlite3_column_text(statement, 0))
                let bookCode = String(cString: sqlite3_column_text(statement, 1))
                let bookName = String(cString: sqlite3_column_text(statement, 2))
                let bookOrder = Int(sqlite3_column_int(statement, 3))
                let chapter = Int(sqlite3_column_int(statement, 4))
                let verse = Int(sqlite3_column_int(statement, 5))
                let verseText = String(cString: sqlite3_column_text(statement, 6))
                let versionCode = String(cString: sqlite3_column_text(statement, 7))
                
                sqlite3_finalize(statement)
                
                return BibleVerse(
                    id: verseId,
                    bookCode: bookCode,
                    bookName: bookName,
                    bookOrder: bookOrder,
                    chapter: chapter,
                    verse: verse,
                    verseText: verseText,
                    versionCode: versionCode
                )
            }
        }
        
        sqlite3_finalize(statement)
        return nil
    }
    
    func getVersesInRange(startVerse: BibleVerse, endVerse: BibleVerse, versionCode: String = "KRV") -> [BibleVerse] {
        var verses: [BibleVerse] = []
        
        // 같은 책, 같은 장인 경우
        if startVerse.bookCode == endVerse.bookCode && startVerse.chapter == endVerse.chapter {
            let query = "SELECT * FROM bible_verse WHERE book_code = ? AND chapter = ? AND verse BETWEEN ? AND ? AND version_code = ? ORDER BY verse"
            
            var statement: OpaquePointer?
            let result = sqlite3_prepare_v2(database, query, -1, &statement, nil)
            
            if result == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (startVerse.bookCode as NSString).utf8String, -1, nil)
                sqlite3_bind_int(statement, 2, Int32(startVerse.chapter))
                sqlite3_bind_int(statement, 3, Int32(startVerse.verse))
                sqlite3_bind_int(statement, 4, Int32(endVerse.verse))
                sqlite3_bind_text(statement, 5, (versionCode as NSString).utf8String, -1, nil)
                
                while sqlite3_step(statement) == SQLITE_ROW {
                    let verseId = String(cString: sqlite3_column_text(statement, 0))
                    let bookCode = String(cString: sqlite3_column_text(statement, 1))
                    let bookName = String(cString: sqlite3_column_text(statement, 2))
                    let bookOrder = Int(sqlite3_column_int(statement, 3))
                    let chapter = Int(sqlite3_column_int(statement, 4))
                    let verse = Int(sqlite3_column_int(statement, 5))
                    let verseText = String(cString: sqlite3_column_text(statement, 6))
                    let versionCode = String(cString: sqlite3_column_text(statement, 7))
                    
                    let bibleVerse = BibleVerse(
                        id: verseId,
                        bookCode: bookCode,
                        bookName: bookName,
                        bookOrder: bookOrder,
                        chapter: chapter,
                        verse: verse,
                        verseText: verseText,
                        versionCode: versionCode
                    )
                    
                    verses.append(bibleVerse)
                }
            }
            
            sqlite3_finalize(statement)
        }
        
        return verses
    }
    
    func searchVerses(keyword: String, versionCode: String = "KRV") -> [BibleVerse] {
        var verses: [BibleVerse] = []
        
        let query = "SELECT * FROM bible_verse WHERE verse_text LIKE ? AND version_code = ? ORDER BY book_order, chapter, verse LIMIT 50"
        
        var statement: OpaquePointer?
        let result = sqlite3_prepare_v2(database, query, -1, &statement, nil)
        
        if result == SQLITE_OK {
            let keywordPattern = "%\(keyword)%"
            sqlite3_bind_text(statement, 1, (keywordPattern as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (versionCode as NSString).utf8String, -1, nil)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                let verseId = String(cString: sqlite3_column_text(statement, 0))
                let bookCode = String(cString: sqlite3_column_text(statement, 1))
                let bookName = String(cString: sqlite3_column_text(statement, 2))
                let bookOrder = Int(sqlite3_column_int(statement, 3))
                let chapter = Int(sqlite3_column_int(statement, 4))
                let verse = Int(sqlite3_column_int(statement, 5))
                let verseText = String(cString: sqlite3_column_text(statement, 6))
                let versionCode = String(cString: sqlite3_column_text(statement, 7))
                
                let bibleVerse = BibleVerse(
                    id: verseId,
                    bookCode: bookCode,
                    bookName: bookName,
                    bookOrder: bookOrder,
                    chapter: chapter,
                    verse: verse,
                    verseText: verseText,
                    versionCode: versionCode
                )
                
                verses.append(bibleVerse)
            }
        }
        
        sqlite3_finalize(statement)
        return verses
    }
    
    func getVerseById(_ verseId: String) -> BibleVerse? {
        let query = "SELECT * FROM bible_verse WHERE verse_id = ?"
        var statement: OpaquePointer?
        let result = sqlite3_prepare_v2(database, query, -1, &statement, nil)
        if result == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (verseId as NSString).utf8String, -1, nil)
            if sqlite3_step(statement) == SQLITE_ROW {
                let verseId = String(cString: sqlite3_column_text(statement, 0))
                let bookCode = String(cString: sqlite3_column_text(statement, 1))
                let bookName = String(cString: sqlite3_column_text(statement, 2))
                let bookOrder = Int(sqlite3_column_int(statement, 3))
                let chapter = Int(sqlite3_column_int(statement, 4))
                let verse = Int(sqlite3_column_int(statement, 5))
                let verseText = String(cString: sqlite3_column_text(statement, 6))
                let versionCode = String(cString: sqlite3_column_text(statement, 7))
                sqlite3_finalize(statement)
                return BibleVerse(
                    id: verseId,
                    bookCode: bookCode,
                    bookName: bookName,
                    bookOrder: bookOrder,
                    chapter: chapter,
                    verse: verse,
                    verseText: verseText,
                    versionCode: versionCode
                )
            }
        }
        sqlite3_finalize(statement)
        return nil
    }
} 
