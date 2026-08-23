package application

import "context"

type Store interface {
	ExecTx(ctx context.Context, fn func(Store) error) error
}
