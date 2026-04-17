import Foundation

/// Simple undo stack for score entry
final class UndoStack<T> {
    private var undoStack: [T] = []
    private var redoStack: [T] = []
    private let maxSize: Int

    init(maxSize: Int = 20) {
        self.maxSize = maxSize
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func push(_ state: T) {
        undoStack.append(state)
        redoStack.removeAll()
        if undoStack.count > maxSize {
            undoStack.removeFirst()
        }
    }

    func undo() -> T? {
        guard let last = undoStack.popLast() else { return nil }
        redoStack.append(last)
        return undoStack.last
    }

    func redo() -> T? {
        guard let last = redoStack.popLast() else { return nil }
        undoStack.append(last)
        return last
    }

    func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
    }
}
