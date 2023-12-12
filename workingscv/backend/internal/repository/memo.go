package repository

import (
    "errors"
    "sync"

    "github.com/workingscv/backend/internal/model"
)

type MemoRepository struct {
    mu    sync.Mutex
    memos []model.Memo
    idSeq int
}

func NewMemoRepository() *MemoRepository {
    return &MemoRepository{
        memos: make([]model.Memo, 0),
        idSeq: 1,
    }
}

func (r *MemoRepository) CreateMemo(memo model.Memo) (int, error) {
    r.mu.Lock()
    defer r.mu.Unlock()

    memo.ID = r.idSeq
    r.idSeq++
    r.memos = append(r.memos, memo)

    return memo.ID, nil
}

func (r *MemoRepository) GetMemoByID(id int) (model.Memo, error) {
    r.mu.Lock()
    defer r.mu.Unlock()

    for _, memo := range r.memos {
        if memo.ID == id {
            return memo, nil
        }
    }

    return model.Memo{}, errors.New("memo not found")
}

func (r *MemoRepository) UpdateMemo(updatedMemo model.Memo) error {
    r.mu.Lock()
    defer r.mu.Unlock()

    for i, memo := range r.memos {
        if memo.ID == updatedMemo.ID {
            r.memos[i] = updatedMemo
            return nil
        }
    }

    return errors.New("memo not found")
}

func (r *MemoRepository) DeleteMemo(id int) error {
    r.mu.Lock()
    defer r.mu.Unlock()

    for i, memo := range r.memos {
        if memo.ID == id {
            r.memos = append(r.memos[:i], r.memos[i+1:]...)
            return nil
        }
    }

    return errors.New("memo not found")
}

func (r *MemoRepository) GetAllMemos() []model.Memo {
    r.mu.Lock()
    defer r.mu.Unlock()

    return r.memos
}
