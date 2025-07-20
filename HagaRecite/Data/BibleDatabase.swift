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
        // 실제 앱에서는 번들에 포함된 SQLite 파일을 사용
        // 여기서는 임시로 메모리 데이터베이스를 생성
        let result = sqlite3_open(":memory:", &database)
        
        if result != SQLITE_OK {
            print("데이터베이스 열기 실패: \(result)")
            return
        }
        
        createTable()
        insertSampleData()
    }
    
    private func createTable() {
        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS bible_verse (
            verse_id TEXT NOT NULL,
            book_code TEXT NOT NULL,
            book_name TEXT NOT NULL,
            book_order INTEGER NOT NULL,
            chapter INTEGER NOT NULL,
            verse INTEGER NOT NULL,
            verse_text TEXT,
            version_code TEXT NOT NULL,
            PRIMARY KEY(verse_id)
        );
        """
        
        var statement: OpaquePointer?
        let result = sqlite3_prepare_v2(database, createTableSQL, -1, &statement, nil)
        
        if result == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("테이블 생성 성공")
            }
        } else {
            print("테이블 생성 실패: \(result)")
        }
        
        sqlite3_finalize(statement)
    }
    
    private func insertSampleData() {
        // 샘플 데이터 삽입 (실제 앱에서는 완전한 성경 데이터를 사용)
        let sampleVerses = [
            ("JHN_3_16_KRV", "JHN", "요한복음", 43, 3, 16, "하나님이 세상을 이처럼 사랑하사 독생자를 주셨으니 이는 그를 믿는 자마다 멸망하지 않고 영생을 얻게 하려 하심이라", "KRV"),
            ("JHN_3_17_KRV", "JHN", "요한복음", 43, 3, 17, "하나님이 그 아들을 세상에 보내신 것은 세상을 정죄하려 하심이 아니요 그로 말미암아 세상이 구원을 받게 하려 하심이라", "KRV"),
            ("PSA_23_1_KRV", "PSA", "시편", 19, 23, 1, "여호와는 나의 목자시니 내게 부족함이 없으리로다", "KRV"),
            ("PSA_23_2_KRV", "PSA", "시편", 19, 23, 2, "그가 나를 푸른 풀밭에 누이시며 쉴 만한 물가로 인도하시는도다", "KRV"),
            ("PSA_23_3_KRV", "PSA", "시편", 19, 23, 3, "내 영혼을 소생시키시고 자기 이름을 위하여 의의 길로 인도하시는도다", "KRV"),
            ("MAT_6_9_KRV", "MAT", "마태복음", 40, 6, 9, "그러므로 너희는 이렇게 기도하라 하늘에 계신 우리 아버지여 이름이 거룩히 여김을 받으시며", "KRV"),
            ("MAT_6_10_KRV", "MAT", "마태복음", 40, 6, 10, "나라가 임하시며 뜻이 하늘에서 이루어진 것같이 땅에서도 이루어지이다", "KRV"),
            ("ROM_8_28_KRV", "ROM", "로마서", 45, 8, 28, "우리가 알거니와 하나님을 사랑하는 자 곧 그 뜻대로 부르심을 받은 자들에게는 모든 것이 합력하여 선을 이루느니라", "KRV"),
            ("PHI_4_13_KRV", "PHP", "빌립보서", 50, 4, 13, "내게 능력 주시는 자 안에서 내가 모든 것을 할 수 있느니라", "KRV"),
            ("JER_29_11_KRV", "JER", "예레미야", 24, 29, 11, "너희를 향한 내 생각을 내가 아나니 곧 너희에게 평안이 아닌 재앙을 주려 하는 생각이라 여호와의 말씀이니라", "KRV")
        ]
        
        let insertSQL = "INSERT OR REPLACE INTO bible_verse (verse_id, book_code, book_name, book_order, chapter, verse, verse_text, version_code) VALUES (?, ?, ?, ?, ?, ?, ?, ?)"
        
        var statement: OpaquePointer?
        let result = sqlite3_prepare_v2(database, insertSQL, -1, &statement, nil)
        
        if result == SQLITE_OK {
            for verse in sampleVerses {
                sqlite3_bind_text(statement, 1, (verse.0 as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (verse.1 as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 3, (verse.2 as NSString).utf8String, -1, nil)
                sqlite3_bind_int(statement, 4, Int32(verse.3))
                sqlite3_bind_int(statement, 5, Int32(verse.4))
                sqlite3_bind_int(statement, 6, Int32(verse.5))
                sqlite3_bind_text(statement, 7, (verse.6 as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 8, (verse.7 as NSString).utf8String, -1, nil)
                
                if sqlite3_step(statement) != SQLITE_DONE {
                    print("데이터 삽입 실패")
                }
                
                sqlite3_reset(statement)
            }
            print("샘플 데이터 삽입 완료")
        }
        
        sqlite3_finalize(statement)
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
            let searchPattern = "%\(keyword)%"
            sqlite3_bind_text(statement, 1, (searchPattern as NSString).utf8String, -1, nil)
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
    
    func getBooks() -> [BibleBook] {
        return BibleBook.allBooks
    }
    
    func getVersions() -> [BibleVersion] {
        return BibleVersion.allVersions
    }
} 