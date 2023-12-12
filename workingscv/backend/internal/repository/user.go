package repository

import (
    "errors"
    "sync"

    "github.com/your-username/my-was-project/internal/model"
)

type UserRepository struct {
    mu    sync.Mutex
    users []model.User
    idSeq int
}

func NewUserRepository() *UserRepository {
    return &UserRepository{
        users: make([]model.User, 0),
        idSeq: 1,
    }
}

func (r *UserRepository) CreateUser(user model.User) (int, error) {
    r.mu.Lock()
    defer r.mu.Unlock()

    // 예시로 간단한 ID 증가 방식 사용
    user.ID = r.idSeq
    r.idSeq++
    r.users = append(r.users, user)

    return user.ID, nil
}

func (r *UserRepository) GetUserByID(id int) (model.User, error) {
    r.mu.Lock()
    defer r.mu.Unlock()

    for _, user := range r.users {
        if user.ID == id {
            return user, nil
        }
    }

    return model.User{}, errors.New("user not found")
}

func (r *UserRepository) GetUserByUsername(username string) (model.User, error) {
    r.mu.Lock()
    defer r.mu.Unlock()

    for _, user := range r.users {
        if user.Username == username {
            return user, nil
        }
    }

    return model.User{}, errors.New("user not found")
}

func (r *UserRepository) DeleteUser(id int) error {
    r.mu.Lock()
    defer r.mu.Unlock()

    for i, user := range r.users {
        if user.ID == id {
            r.users = append(r.users[:i], r.users[i+1:]...)
            return nil
        }
    }

    return errors.New("user not found")
}
