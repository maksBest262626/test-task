<?php

declare(strict_types=1);

namespace App\Dto\Api\Transformer;

use App\Dto\DtoFactory;
use App\Dto\Api\UserDto;
use App\Entity\User;
use App\Dto\AbstractTransformer;

final class UserDtoTransformer extends AbstractTransformer
{
    public function __construct(
        protected DtoFactory $dtoFactory
    ) { }

    /**
     * @param User $object
     */
    public function transformFromObject($object): UserDto
    {
        $dto = $this->dtoFactory->create(
            UserDto::class,
            [
                'first_name' => $object->getFirstName(),
                'last_name' => $object->getLastName(),
                'email' => $object->getEmail(),
                'password' => $object->getPassword()
            ]
        );

        if ($errors = $this->dtoFactory->validate($dto)) {
            throw new \RuntimeException('Validation error: ' . implode(', ', $errors));
        }

        return $dto;
    }
}