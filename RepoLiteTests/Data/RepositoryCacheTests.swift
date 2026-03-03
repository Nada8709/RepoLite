//
//  RepositoryCacheTests.swift
//  RepoLiteTests
//

import XCTest
@testable import RepoLite

final class RepositoryCacheTests: XCTestCase {

    private var sut: RepositoryCache!

    override func setUp() {
        super.setUp()
        sut = RepositoryCache(ttl: 300)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Store & Retrieve

    func test_retrieve_returnsNil_whenNothingStored() {
        XCTAssertNil(sut.retrieve(page: 1))
    }

    func test_store_andRetrieve_returnsSameRepos() {
        // Given
        let repos = [Repository.stub(id: 1), Repository.stub(id: 2)]

        // When
        sut.store(repos, page: 1)
        let retrieved = sut.retrieve(page: 1)

        // Then
        XCTAssertEqual(retrieved?.count, 2)
        XCTAssertEqual(retrieved?.map(\.id), [1, 2])
    }

    func test_retrieve_returnsDifferentPages_independently() {
        // Given
        let page1Repos = [Repository.stub(id: 1)]
        let page2Repos = [Repository.stub(id: 2), Repository.stub(id: 3)]

        // When
        sut.store(page1Repos, page: 1)
        sut.store(page2Repos, page: 2)

        // Then
        XCTAssertEqual(sut.retrieve(page: 1)?.count, 1)
        XCTAssertEqual(sut.retrieve(page: 2)?.count, 2)
    }

    func test_store_overwritesExistingEntry_forSamePage() {
        // Given
        sut.store([Repository.stub(id: 1)], page: 1)

        // When — overwrite with new data
        sut.store([Repository.stub(id: 10), Repository.stub(id: 11)], page: 1)

        // Then
        XCTAssertEqual(sut.retrieve(page: 1)?.count, 2)
        XCTAssertEqual(sut.retrieve(page: 1)?.first?.id, 10)
    }

    // MARK: - TTL Expiry

    func test_retrieve_returnsNil_afterTTLExpires() {
        // Given — cache with 0 second TTL
        sut = RepositoryCache(ttl: 0)
        sut.store([Repository.stub()], page: 1)

        // When — TTL already expired
        let result = sut.retrieve(page: 1)

        // Then
        XCTAssertNil(result)
    }

    func test_retrieve_returnsData_beforeTTLExpires() {
        // Given — long TTL
        sut = RepositoryCache(ttl: 3600)
        sut.store([Repository.stub()], page: 1)

        // When
        let result = sut.retrieve(page: 1)

        // Then
        XCTAssertNotNil(result)
    }

    // MARK: - Invalidate

    func test_invalidate_clearsAllEntries() {
        // Given
        sut.store([Repository.stub(id: 1)], page: 1)
        sut.store([Repository.stub(id: 2)], page: 2)
        sut.store([Repository.stub(id: 3)], page: 3)

        // When
        sut.invalidate()

        // Then
        XCTAssertNil(sut.retrieve(page: 1))
        XCTAssertNil(sut.retrieve(page: 2))
        XCTAssertNil(sut.retrieve(page: 3))
    }

    func test_invalidate_allowsNewStorageAfterClearing() {
        // Given
        sut.store([Repository.stub(id: 1)], page: 1)
        sut.invalidate()

        // When — store new data after invalidation
        sut.store([Repository.stub(id: 99)], page: 1)

        // Then
        XCTAssertEqual(sut.retrieve(page: 1)?.first?.id, 99)
    }
}
