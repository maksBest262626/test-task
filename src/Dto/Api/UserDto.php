<?php

namespace App\Dto\Api;

use App\Dto\AbstractDto;
use JMS\Serializer\Annotation as Serialization;
use Symfony\Component\Validator\Constraints as Assert;

/**
 * @see https://github.com/esteit/docs/blob/master/%D0%9F%D1%80%D0%BE%D1%82%D0%BE%D0%BA%D0%BE%D0%BB%20%D0%BA%D0%BE%D0%BC%D0%BC%D1%83%D0%BD%D0%B8%D0%BA%D0%B0%D1%86%D0%B8%D0%B8%20ZeStore%20%D1%81%20%D0%BF%D1%80%D0%BE%D0%B5%D0%BA%D1%82%D0%B0%D0%BC%D0%B8.md#%D1%81%D1%83%D1%89%D0%BD%D0%BE%D1%81%D1%82%D1%8C-user
 */
final class UserDto extends AbstractDto
{
    #[Assert\Type("string")]
    #[Assert\NotBlank]
    #[Assert\Length(null, 3, 60)]
    #[Serialization\Type("string")]
    protected string $firstName;

    #[Assert\Type("string")]
    #[Assert\Length(null, 3, 60)]
    #[Serialization\Type("string")]
    protected string $lastName;

    #[Assert\Type("string")]
    #[Assert\Length(null, 3, 180)]
    #[Serialization\Type("string")]
    protected string $email;

    #[Assert\Type("string")]
    #[Assert\NotBlank]
    #[Assert\Length(null, 3)]
    #[Serialization\Type("string")]
    protected string $password;

    public function getEmail(): string
    {
        return $this->email;
    }

    public function getFirstName(): string
    {
        return $this->firstName;
    }

    public function getLastName(): string
    {
        return $this->lastName;
    }

    public function getPassword(): string
    {
        return $this->password;
    }
}